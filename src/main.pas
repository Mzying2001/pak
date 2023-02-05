unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonStart: TButton;
    EditButtonInput: TEditButton;
    EditButtonOutput: TEditButton;
    Label1: TLabel;
    Label2: TLabel;
    RadioButtonPak: TRadioButton;
    RadioButtonUnpak: TRadioButton;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin

end;

end.

