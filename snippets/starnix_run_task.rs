/// Runs the given task.
///
/// The task is expected to already have been started. This function listens to
/// the exception channel for the process (`exceptions`) and handles each
///  exception by:
///
///   - verifying that the exception represents a `ZX_EXCP_POLICY_CODE_BAD_SYSCALL`
///   - reading the thread's registers
///   - executing the appropriate syscall
///   - setting the thread's registers to their post-syscall values
///   - setting the exception state to `ZX_EXCEPTION_STATE_HANDLED`
///
/// Once this function has completed, the process' exit code (if one is available) can be read from
/// `process_context.exit_code`.
fn run_task(mut current_task: CurrentTask, exceptions: zx::Channel) -> Result<i32, Error> {
    let mut buffer = zx::MessageBuf::new();
    loop {
        read_channel_sync(&exceptions, &mut buffer)?;

        let info = as_exception_info(&buffer);
        assert!(buffer.n_handles() == 1);
        let exception = zx::Exception::from(buffer.take_handle(0).unwrap());

        if info.type_ != ZX_EXCP_POLICY_ERROR {
            info!("exception type: 0x{:x}", info.type_);
            exception.set_exception_state(&ZX_EXCEPTION_STATE_TRY_NEXT)?;
            continue;
        }

        let thread = exception.get_thread()?;
        assert!(
            thread.get_koid() == current_task.thread.get_koid(),
            "Exception thread did not match task thread."
        );

        let report = thread.get_exception_report()?;
        if report.context.synth_code != ZX_EXCP_POLICY_CODE_BAD_SYSCALL {
            info!("exception synth_code: {}", report.context.synth_code);
            exception.set_exception_state(&ZX_EXCEPTION_STATE_TRY_NEXT)?;
            continue;
        }

        let syscall_number = report.context.synth_data as u64;
        current_task.registers = thread.read_state_general_regs()?;

        let regs = &current_task.registers;
        let args = (regs.rdi, regs.rsi, regs.rdx, regs.r10, regs.r8, regs.r9);
        strace!(
            current_task,
            "{}({:#x}, {:#x}, {:#x}, {:#x}, {:#x}, {:#x})",
            SyscallDecl::from_number(syscall_number).name,
            args.0,
            args.1,
            args.2,
            args.3,
            args.4,
            args.5
        );
        match dispatch_syscall(&mut current_task, syscall_number, args) {
            Ok(SyscallResult::Exit(error_code)) => {
                strace!(current_task, "-> exit {:#x}", error_code);
                exception.set_exception_state(&ZX_EXCEPTION_STATE_THREAD_EXIT)?;
                return Ok(error_code);
            }
            Ok(SyscallResult::Success(return_value)) => {
                strace!(current_task, "-> {:#x}", return_value);
                current_task.registers.rax = return_value;
            }
            Ok(SyscallResult::SigReturn) => {
                // Do not modify the register state of the thread. The sigreturn syscall has
                // restored the proper register state for the thread to continue with.
                strace!(current_task, "-> sigreturn");
            }
            Err(errno) => {
                strace!(current_task, "!-> {}", errno);
                current_task.registers.rax = (-errno.value()) as u64;
            }
        }

        dequeue_signal(&mut current_task);
        thread.write_state_general_regs(current_task.registers)?;
        exception.set_exception_state(&ZX_EXCEPTION_STATE_HANDLED)?;
    }
}
