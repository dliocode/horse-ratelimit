program Teste2;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Horse.Commons in 'modules\horse\src\Horse.Commons.pas',
  Horse.Constants in 'modules\horse\src\Horse.Constants.pas',
  Horse.Core in 'modules\horse\src\Horse.Core.pas',
  Horse.Core.Route.Intf in 'modules\horse\src\Horse.Core.Route.Intf.pas',
  Horse.Core.Route in 'modules\horse\src\Horse.Core.Route.pas',
  Horse.Exception in 'modules\horse\src\Horse.Exception.pas',
  Horse.HTTP in 'modules\horse\src\Horse.HTTP.pas',
  Horse.ISAPI in 'modules\horse\src\Horse.ISAPI.pas',
  Horse in 'modules\horse\src\Horse.pas',
  Horse.Router in 'modules\horse\src\Horse.Router.pas',
  Horse.WebModule in 'modules\horse\src\Horse.WebModule.pas' {HorseWebModule: TWebModule},
  Horse.RateLimit in '..\src\Horse.RateLimit.pas',
  Horse.RateLimit.Store.Intf in '..\src\Horse.RateLimit.Store.Intf.pas',
  Horse.RateLimit.Store.Memory in '..\src\Horse.RateLimit.Store.Memory.pas',
  Horse.RateLimit.Utils in '..\src\Horse.RateLimit.Utils.pas';

var
  App: THorse;
  RLPing: THorseRateLimit;
  RLTest: THorseRateLimit;
  Config: TRateLimitConfig;
begin
  App := THorse.Create(9000);

  Config.Id := 'Ping'; // Identification
  Config.Limit := 5; // Limit Request
  Config.Timeout := 30; // Timeout in seconds
  Config.Message := ''; // Message return
  Config.Headers := True; // Show in Header X-Rate-Limit-*
  Config.Store := nil; // Default TMemoryStore
  Config.SkipFailedRequest := False; // Undo if the response request was failed
  Config.SkipSuccessRequest := False; // Undo if the response request was successful

  RLPing := THorseRateLimit.Create(Config);

  App.Get('/ping',
    RLPing.Limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  // Max of 30 Request in 5 minutes with return custom message
  Config.Id := 'Test';
  Config.Limit := 30;
  Config.Timeout := 5 * 60;
  Config.Message := 'My Custom Message';
  Config.Headers := True;

  RLTest:= THorseRateLimit.Create(Config);
  App.Get('/test',
    RLTest.Limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('ok');
    end);

  App.Start;
end.
