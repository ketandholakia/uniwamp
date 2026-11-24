unit Core.UniWamp.TaskRunner;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Threading;

type
  TTaskCallback = reference to procedure;
  TTaskErrorCallback = reference to procedure(const ErrorMessage: string);
  TTaskAction = reference to procedure;

  TTaskRunner = class
  public
    class procedure Run(const Action: TTaskAction;
      const OnSuccess: TTaskCallback = nil;
      const OnError: TTaskErrorCallback = nil;
      const QueueThread: TThread = nil); static;
  end;

implementation

uses
  System.IOUtils,
  Core.UniWamp.Diagnostics,
  Core.UniWamp.Paths;

class procedure TTaskRunner.Run(const Action: TTaskAction;
  const OnSuccess: TTaskCallback;
  const OnError: TTaskErrorCallback;
  const QueueThread: TThread);
begin
  TTask.Run(TProc(
    procedure
    begin
      try
        if Assigned(Action) then
          Action();

        if Assigned(OnSuccess) then
        begin
          if Assigned(QueueThread) then
            TThread.Queue(QueueThread, TThreadProcedure(
              procedure
              begin
                OnSuccess();
              end))
          else
            OnSuccess();
        end;
      except
        on E: Exception do
        begin
          if Assigned(OnError) then
          begin
            // Capture message to local variable for closure
            var ErrorMsg := E.Message;
            if Assigned(QueueThread) then
              TThread.Queue(QueueThread, TThreadProcedure(
                procedure
                begin
                  OnError(ErrorMsg);
                end))
            else
              OnError(ErrorMsg);
          end
          else
          begin
            // Without a handler the failure would vanish silently; surface it
            // in the activity log instead of swallowing it.
            try
              AppendRotatedLogLine(
                TPath.Combine(TAppPaths.Detect.LogsDir, 'activity.log'),
                FormatDateTime('hh:nn:ss', Now) + '  Background task error: ' + E.Message,
                500);
            except
              // Logging must never mask the original failure path.
            end;
          end;
        end;
      end;
    end));
end;

end.
