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

  if not Trim(Req.Headers['HTTP_CLIENT_IP']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_CLIENT_IP']));

  for LIP in Trim(Req.Headers['HTTP_X_FORWARDED_FOR']).Split([',']) do
    if not Trim(LIP).IsEmpty then
      Exit(Trim(LIP));

  if not Trim(Req.Headers['HTTP_X_FORWARDED']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_X_FORWARDED']));

  if not Trim(Req.Headers['HTTP_X_CLUSTER_CLIENT_IP']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_X_CLUSTER_CLIENT_IP']));

  if not Trim(Req.Headers['HTTP_FORWARDED_FOR']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_FORWARDED_FOR']));

  if not Trim(Req.Headers['HTTP_FORWARDED']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_FORWARDED']));

  if not Trim(Req.Headers['REMOTE_ADDR']).IsEmpty then
    Exit(Trim(Req.Headers['REMOTE_ADDR']));

  if not Trim(THorseHackRequest(Req).GetWebRequest.RemoteIP).IsEmpty then
    Exit(Trim(THorseHackRequest(Req).GetWebRequest.RemoteIP));

  if not Trim(THorseHackRequest(Req).GetWebRequest.RemoteAddr).IsEmpty then
    Exit(Trim(THorseHackRequest(Req).GetWebRequest.RemoteAddr));

  if not Trim(THorseHackRequest(Req).GetWebRequest.RemoteHost).IsEmpty then
    Exit(Trim(THorseHackRequest(Req).GetWebRequest.RemoteHost));
end;

end.
