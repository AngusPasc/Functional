{****************************************************}
{                                                    }
{  Delphi Functional Library                         }
{                                                    }
{  Copyright (C) 2015 Colin Johnsun                  }
{                                                    }
{  https:/github.com/colinj                          }
{                                                    }
{****************************************************}
{                                                    }
{  This Source Code Form is subject to the terms of  }
{  the Mozilla Public License, v. 2.0. If a copy of  }
{  the MPL was not distributed with this file, You   }
{  can obtain one at                                 }
{                                                    }
{  http://mozilla.org/MPL/2.0/                       }
{                                                    }
{****************************************************}

unit Functional.Sequence;

interface

uses
  SysUtils, Classes,
  Generics.Collections,
  DB,
  Functional.Value,
  Functional.FuncFactory;

type
  TSeq<T, U> = record
  private
    FFunc: TValueFunc<T, U>;
    FIterate: TIteratorProc<T>;
  public
    function Filter(const aPredicate: TPredicate<U>): TSeq<T, U>;
    function Where(const aPredicate: TPredicate<U>): TSeq<T, U>; // synonym for Filter function
    function Map(const aMapper: TFunc<U, U>): TSeq<T, U>; overload;
    function Map<TResult>(const aMapper: TFunc<U, TResult>): TSeq<T, TResult>; overload;
    function Select(const aMapper: TFunc<U, U>): TSeq<T, U>; overload; // synonum for Map function
    function Select<TResult>(const aMapper: TFunc<U, TResult>): TSeq<T, TResult>; overload; // synonym for Map function
    function Take(const aCount: Integer): TSeq<T, U>;
    function Skip(const aCount: Integer): TSeq<T, U>;
    function TakeWhile(const aPredicate: TPredicate<U>): TSeq<T, U>;
    function SkipWhile(const aPredicate: TPredicate<U>): TSeq<T, U>;
    function Fold<TResult>(const aFoldFunc: TFoldFunc<U, TResult>; const aInitVal: TResult): TResult;
    function ToList: TList<U>;
    procedure ForEach(const aAction: TProc<U>);
  end;

  TSeq = record
  public
    class function Identity<T>(Item: TValue<T>): TValue<T>; static;
    class function From<T>(const aArray: TArray<T>): TSeq<T, T>; overload; static;
    class function From<T>(const aEnumerable: TEnumerable<T>): TSeq<T, T>; overload; static;
    class function From(const aString: string): TSeq<Char, Char>; overload; static;
    class function From(const aStrings: TStrings): TSeq<string, string>; overload; static;
    class function From(const aDataset: TDataSet): TSeq<TDataSet, TDataSet>; overload; static;
    class function Range(const aStart, aFinish: Integer): TSeq<Integer, Integer>; static;
  end;

implementation

{ TSeq<T, U> }

function TSeq<T, U>.Filter(const aPredicate: TPredicate<U>): TSeq<T, U>;
begin
  Result.FFunc := TFuncFactory<T, U>.Filter(FFunc, aPredicate);
  Result.FIterate := FIterate;
end;

function TSeq<T, U>.Where(const aPredicate: TPredicate<U>): TSeq<T, U>;
begin
  Result := Filter(aPredicate);
end;

function TSeq<T, U>.Map(const aMapper: TFunc<U, U>): TSeq<T, U>;
begin
  Result.FFunc := TFuncFactory<T, U>.Map<U>(FFunc, aMapper);
  Result.FIterate := FIterate;
end;

function TSeq<T, U>.Map<TResult>(const aMapper: TFunc<U, TResult>): TSeq<T, TResult>;
begin
  Result.FFunc := TFuncFactory<T, U>.Map<TResult>(FFunc, aMapper);
  Result.FIterate := FIterate;
end;

function TSeq<T, U>.Select(const aMapper: TFunc<U, U>): TSeq<T, U>;
begin
  Result := Map(aMapper);
end;

function TSeq<T, U>.Select<TResult>(const aMapper: TFunc<U, TResult>): TSeq<T, TResult>;
begin
  Result := Map<TResult>(aMapper);
end;

function TSeq<T, U>.Take(const aCount: Integer): TSeq<T, U>;
begin
  Result.FFunc := TFuncFactory<T, U>.Take(FFunc, aCount);
  Result.FIterate := FIterate;
end;

function TSeq<T, U>.TakeWhile(const aPredicate: TPredicate<U>): TSeq<T, U>;
begin
  Result.FFunc := TFuncFactory<T, U>.TakeWhile(FFunc, aPredicate);
  Result.FIterate := FIterate;
end;

function TSeq<T, U>.Skip(const aCount: Integer): TSeq<T, U>;
begin
  Result.FFunc := TFuncFactory<T, U>.Skip(FFunc, aCount);
  Result.FIterate := FIterate;
end;

function TSeq<T, U>.SkipWhile(const aPredicate: TPredicate<U>): TSeq<T, U>;
begin
  Result.FFunc := TFuncFactory<T, U>.SkipWhile(FFunc, aPredicate);
  Result.FIterate := FIterate;
end;

procedure TSeq<T, U>.ForEach(const aAction: TProc<U>);
begin
  FFunc(TValue<T>.Start);
  FIterate(TFuncFactory<T, U>.ForEach(FFunc, aAction));
end;

function TSeq<T, U>.ToList: TList<U>;
begin
  Result := TList<U>.Create;
  FIterate(TFuncFactory<T, U>.AddItem(FFunc, Result));
end;

function TSeq<T, U>.Fold<TResult>(const aFoldFunc: TFoldFunc<U, TResult>; const aInitVal: TResult): TResult;
var
  OrigFunc: TValueFunc<T, U>;
  Accumulator: TResult;
begin
  OrigFunc := FFunc;

  Accumulator := aInitVal;
  OrigFunc(TValue<T>.Start);

  FIterate(
    function (Item: T): Boolean
    var
      R: TValue<U>;
    begin
      Result := False;
      R := OrigFunc(TValue<T>(Item));
      case R.State of
        vsSomething: Accumulator := aFoldFunc(R.Value, Accumulator);
        vsFinish: Result := True;
      end;
    end
  );

  Result := Accumulator;
end;

{ TSeq }

class function TSeq.Identity<T>(Item: TValue<T>): TValue<T>;
begin
  Result := Item;
end;

class function TSeq.From<T>(const aArray: TArray<T>): TSeq<T, T>;
begin
  Result.FFunc := Identity<T>;
  Result.FIterate :=
    procedure (StopOn: TPredicate<T>)
    var
      Item: T;
    begin
      for Item in aArray do
        if StopOn(Item) then Break;
    end;
end;

class function TSeq.From<T>(const aEnumerable: TEnumerable<T>): TSeq<T, T>;
begin
  Result.FFunc := Identity<T>;
  Result.FIterate :=
    procedure (StopOn: TPredicate<T>)
    var
      Item: T;
    begin
      for Item in aEnumerable do
        if StopOn(Item) then Break;
    end;
end;

class function TSeq.From(const aString: string): TSeq<Char, Char>;
begin
  Result.FFunc := Identity<Char>;
  Result.FIterate :=
    procedure (StopOn: TPredicate<Char>)
    var
      Item: Char;
    begin
      for Item in aString do
        if StopOn(Item) then Break;
    end;
end;

class function TSeq.From(const aStrings: TStrings): TSeq<string, string>;
begin
  Result.FFunc := Identity<string>;
  Result.FIterate :=
    procedure (StopOn: TPredicate<string>)
    var
      Item: string;
    begin
      for Item in aStrings do
        if StopOn(Item) then Break;
    end;
end;

class function TSeq.From(const aDataset: TDataSet): TSeq<TDataSet, TDataSet>;
begin
  Result.FFunc := Identity<TDataSet>;
  Result.FIterate :=
    procedure (StopOn: TPredicate<TDataSet>)
    var
      D: TDataSet;
    begin
      D := aDataset;
      D.First;
      while not D.Eof do
      begin
        if StopOn(D) then Break;
        D.Next;
      end;
    end;
end;

class function TSeq.Range(const aStart, aFinish: Integer): TSeq<Integer, Integer>;
begin
  Result.FFunc := Identity<Integer>;
  Result.FIterate :=
    procedure (StopOn: TPredicate<Integer>)
    var
      Item: Integer;
    begin
      for Item := aStart to aFinish do
        if StopOn(Item) then Break;
    end;
end;

end.

