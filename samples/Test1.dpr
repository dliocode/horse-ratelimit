program Test1;

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
  RateLimit: THorseRateLimit;
begin
  App := THorse.Create(9000);

  RateLimit := THorseRateLimit.Create();

  App.Use(RateLimit.Limit)

  App.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  App.Start;
end.
