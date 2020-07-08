program Model3;

uses Horse, Horse.RateLimit;

var
  App: THorse;
  Config: TRateLimitConfig;
begin
  App := THorse.Create(9000);

  Config.Id := 'ping';                // Identification
  Config.Limit := 5;                  // Limit Request
  Config.Timeout := 30;               // Timeout in seconds
  Config.Message := '';               // Message return
  Config.Headers := True;             // Show in Header X-RateLimit-*
  Config.Store := nil;                // Default TMemoryStore
  Config.SkipFailedRequest := False;  // Undo if the response request was failed
  Config.SkipSuccessRequest := False; // Undo if the response request was successful

  App.Get('/ping', THorseRateLimit.New(Config).limit,
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

  App.Get('/test', THorseRateLimit.New(Config).limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('ok');
    end);

  App.Start;
end.
