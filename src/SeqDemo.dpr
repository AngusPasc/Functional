program SeqDemo;

uses
  Forms,
  fmMain in 'fmMain.pas' {Form6},
  uSequence in 'uSequence.pas',
  uRange in 'uRange.pas',
  uValue in 'uValue.pas',
  uCounter in 'uCounter.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm6, Form6);
  Application.Run;
end.
