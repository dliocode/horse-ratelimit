unit Horse.RateLimit.Utils;

interface

uses
  Horse.HTTP,
  System.SysUtils;

function ClientIP(Req: THorseRequest): string;

implementation

function ClientIP(Req: THorseRequest): string;
var
  LIP: string;
begin
  Result := EmptyStr;

  if not Req.Headers['HTTP_CLIENT_IP'].Trim.IsEmpty then
    Exit(Req.Headers['HTTP_CLIENT_IP'].Trim);

  for LIP in Req.Headers['HTTP_X_FORWARDED_FOR'].Trim.Split([',']) do
    if not LIP.Trim.IsEmpty then
      Exit(LIP.Trim);

  if not Req.Headers['HTTP_X_FORWARDED'].Trim.IsEmpty then
    Exit(Req.Headers['HTTP_X_FORWARDED'].Trim);

  if not Req.Headers['HTTP_X_CLUSTER_CLIENT_IP'].Trim.IsEmpty then
    Exit(Req.Headers['HTTP_X_CLUSTER_CLIENT_IP'].Trim);

  if not Req.Headers['HTTP_FORWARDED_FOR'].Trim.IsEmpty then
    Exit(Req.Headers['HTTP_FORWARDED_FOR'].Trim);

  if not Req.Headers['HTTP_FORWARDED'].Trim.IsEmpty then
    Exit(Req.Headers['HTTP_FORWARDED'].Trim);

  if not Req.Headers['REMOTE_ADDR'].Trim.IsEmpty then
    Exit(Req.Headers['REMOTE_ADDR'].Trim);

  if not THorseHackRequest(Req).GetWebRequest.RemoteIP.Trim.IsEmpty then
    Exit(THorseHackRequest(Req).GetWebRequest.RemoteIP.Trim);

  if not Trim(THorseHackRequest(Req).GetWebRequest.RemoteAddr).IsEmpty then
    Exit(THorseHackRequest(Req).GetWebRequest.RemoteAddr.Trim);

  if not Trim(THorseHackRequest(Req).GetWebRequest.RemoteHost).IsEmpty then
    Exit(THorseHackRequest(Req).GetWebRequest.RemoteHost.Trim);
end;

end.
