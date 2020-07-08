program Model2;

uses Horse, Horse.RateLimit;

var
  App: THorse;
begin
  App := THorse.Create(9000);

  App.Get('/ping', THorseRateLimit.New('ping').limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  App.Get('/book', THorseRateLimit.New('book').limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('The book!');
    end);

  App.Get('/login', THorseRateLimit.New('login',10,60).limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('My Login with Request Max of 10 every 60 seconds!');
    end);

  App.Start;
end.
