unit uValue;

interface

uses
  SysUtils, Classes;

type
  TValueState = (vsStart, vsSomething, vsNothing, vsStop);

  TValue<T> = record
  private
    FValue: T;
    FState: TValueState;
  public
    class operator Implicit(const aValue: T): TValue<T>;
    class function Nothing: TValue<T>; static;
    class function Start: TValue<T>; static;
    class function Stop: TValue<T>; static;
    function IsSomething: Boolean;
    procedure SetState(const aState: TValueState);
    property Value: T read FValue;
    property State: TValueState read FState;
  end;

implementation

{ TValue<T> }

class operator TValue<T>.Implicit(const aValue: T): TValue<T>;
begin
  Result.FValue := aValue;
  Result.FState := vsSomething;
end;

function TValue<T>.IsSomething: Boolean;
begin
  Result := FState = vsSomething;
end;

class function TValue<T>.Nothing: TValue<T>;
begin
  Result.FState := vsNothing;
end;

procedure TValue<T>.SetState(const aState: TValueState);
begin
  FState := aState;
end;

class function TValue<T>.Start: TValue<T>;
begin
  Result.FState := vsStart;
end;

class function TValue<T>.Stop: TValue<T>;
begin
  Result.FState := vsStop;
end;

end.