# Horse-RateLimit

Basic rate-limiting middleware for Horse. Use to limit repeated requests to public APIs and/or endpoints such as password reset.

### For install in your project using [boss](https://github.com/HashLoad/boss):
``` sh
$ boss install github.com/dliocode/horse-ratelimit
```

### Stores

- Memory Store _(default, built-in)_ - stores current in-memory in the Horse process. Does not share state with other servers or processes.
- RedisStore: [Samples - Model 4](https://github.com/dliocode/horse-ratelimit/tree/master/samples/Model%204)

## Usage

For an API-only server where the ratelimit should be applied to all requests: 
Ex: _Store Memory_

```delphi
uses Horse, Horse.RateLimit;
  
var
  App: THorse;
begin
  App := THorse.Create(9000);

  App.Use(THorseRateLimit.New().Limit);

  App.Get('/ping',    
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);
    
  App.Start;
end.
```

Create multiple instances to different routes:
*Identification should always be used when using multiple instances.*

```delphi
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
```

Settings use:

```delphi
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
```

**Note:** Stores require additional configuration, such as custom prefixes, when using multiple instances.

## Configuration options

### Id
 
Identification should always be used when using multiple instances..

### Limit

Max number of request during `Timeout` in seconds before sending a 429 response.

It must be a number. The default is `60`.

### Timeout

Timeframe for which requests are checked/remembered. Also used in the Retry-After header when the limit is reached.

Note: with non-default stores, you may need to configure this value twice, once here and once on the store. In some cases the units also differ (e.g. seconds vs miliseconds)

Defaults to `60` (1 minute).

### Message

Error message sent to user when `Limit` is exceeded.

It must be a string. The default is `'Too many requests, please try again later.'`.

### Headers

Enable headers for request limit (`X-RateLimit-Limit`) and current usage (`X-RateLimit-Remaining`) on all responses and time to wait before retrying (`Retry-After`) when `Limit` is exceeded.

Defaults to `false`. Behavior may change in the next major release.

### SkipFailedRequest

When set to `true`, failed requests won't be counted. Request considered failed when:

- response status >= 400

(Technically they are counted and then un-counted, so a large number of slow requests all at once could still trigger a rate-limit. This may be fixed in a future release.)

Defaults to `false`.

### SkipSuccessRequest

When set to `true` successful requests (response status < 400) won't be counted.
(Technically they are counted and then un-counted, so a large number of slow requests all at once could still trigger a rate-limit. This may be fixed in a future release.)

Defaults to `false`.

### Store

The storage to use when persisting rate limit attempts.

By default, the MemoryStore is used.

Available data stores are:

- MemoryStore: _(default)_ Simple in-memory option. Does not share state when app has multiple processes or servers.
- RedisStore: [Samples - Model 4](https://github.com/dliocode/horse-ratelimit/tree/master/samples/Model%204)

You may also create your own store. It must implement the IStore to function

### Store with Redis

Usage:

To use it you must add to uses `Store.Redis` with the function `TRedisStore.New()`.

Ex: _Store Redis_
```delphi
uses Horse, Horse.RateLimit, Store.Redis;
  
var
  App: THorse;
begin
  App := THorse.Create(9000);

  App.Use(THorseRateLimit.New(10, 60, TRedisStore.New()).Limit);

  App.Get('/ping',    
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);
    
  App.Start;
end.
```

How to configure host, port in Redis
`TRedisStore.New('HOST','PORT','NAME CLIENTE')`

1st Parameter - HOST - Default: `127.0.0.1`

2st Parameter - PORT - Default: `6379`

3st Parameter - ClientName - Default: `Empty`


## License

MIT © [Danilo Lucas](https://github.com/dliocode/)
