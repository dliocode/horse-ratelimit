program Model2;

uses Horse, Horse.RateLimit;

begin
  THorse
  .Get('/ping', THorseRateLimit.New('ping').limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end)

  .Get('/book', THorseRateLimit.New('book').limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('The book!');
    end)

  .Get('/login', THorseRateLimit.New('login',10,60).limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('My Login with Request Max of 10 every 60 seconds!');
    end);

  THorse.Listen(9000);
end.
