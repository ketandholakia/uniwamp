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
      const OnError: TTaskErrorCallback = nil); static;
  end;

implementation

class procedure TTaskRunner.Run(const Action: TTaskAction;
  const OnSuccess: TTaskCallback;
  const OnError: TTaskErrorCallback);
begin
  TTask.Run(TProc(
    procedure
    begin
      try
        if Assigned(Action) then
          Action();

        if Assigned(OnSuccess) then
        begin
          TThread.Queue(nil, TThreadProcedure(
            procedure
            begin
              OnSuccess();
            end));
        end;
      except
        on E: Exception do
        begin
          if Assigned(OnError) then
          begin
            // Capture message to local variable for closure
            var ErrorMsg := E.Message;
            TThread.Queue(nil, TThreadProcedure(
              procedure
              begin
                OnError(ErrorMsg);
              end));
          end;
        end;
      end;
    end));
end;

end.
