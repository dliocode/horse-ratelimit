# Horse-RateLimit

Basic rate-limiting middleware for Horse. Use to limit repeated requests to public APIs and/or endpoints such as password reset.

### For install in your project using [boss](https://github.com/HashLoad/boss):
``` sh
$ boss install github.com/dliocode/horse-ratelimit
```

### Stores

- Memory Store _(default, built-in)_ - stores hits in-memory in the Horse process. Does not share state with other servers or processes.

## Usage

For an API-only server where the ratelimit should be applied to all requests:

```delphi
uses Horse, Horse.RateLimit;
  
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
```

Create multiple instances to apply different rules to different routes:

```delphi
uses Horse, Horse.RateLimit;
  
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
```

**Note:** most stores will require additional configuration, such as custom prefixes, when using multiple instances. The default built-in memory store is an exception to this rule.

## Configuration options

### Id
 
RateLimite identification.

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

Enable headers for request limit (`X-Rate-Limit-Limit`) and current usage (`X-Rate-Limit-Remaining`) on all responses and time to wait before retrying (`Retry-After`) when `Limit` is exceeded.

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
- RedisStore: _(future release)_

You may also create your own store. It must implement the IRateLimitStore to function

## Summary of breaking changes:

## License

MIT © [Danilo Lucas](https://github.com/DaniloLucas-DLIO/)
