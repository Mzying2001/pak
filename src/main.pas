unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonStart: TButton;
    EditButtonPakPath: TEditButton;
    EditButtonUnpakPath: TEditButton;
    Label1: TLabel;
    Label2: TLabel;
    RadioButtonPak: TRadioButton;
    RadioButtonUnpak: TRadioButton;
    procedure ButtonStartClick(Sender: TObject);
    procedure EditButtonInputButtonClick(Sender: TObject);
    procedure EditButtonOutputButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    _isLoading: boolean;
    procedure SetIsLoading(Value: boolean);
  public
    property IsLoading: boolean read _isLoading;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  SetIsLoading(False);
  EditButtonPakPath.Button.OnClick := @EditButtonInputButtonClick;
  EditButtonUnpakPath.Button.OnClick := @EditButtonOutputButtonClick;
end;

procedure TMainForm.ButtonStartClick(Sender: TObject);
var
  inputPath: string;
  outputPath: string;
begin
  inputPath := Trim(EditButtonPakPath.Text);
  outputPath := Trim(EditButtonUnpakPath.Text);

  if inputPath = '' then
  begin
    ShowMessage('请输入pak文件路径');
    exit;
  end;
  if outputPath = '' then
  begin
    ShowMessage('解包/打包路径不能为空');
    exit;
  end;

  if RadioButtonPak.Checked then
  begin
    //TODO: pak
    ShowMessage('pak');
  end
  else if RadioButtonUnpak.Checked then
  begin
    //TODO: unpak
    ShowMessage('unpak');
  end;
end;

procedure TMainForm.EditButtonInputButtonClick(Sender: TObject);
var
  sfd: TSaveDialog;
begin
  sfd := TSaveDialog.Create(self);
  sfd.Title := '选择pak文件';
  sfd.Filter := 'pak文件|*.pak';
  if sfd.Execute then
    EditButtonPakPath.Text := sfd.FileName;
end;

procedure TMainForm.EditButtonOutputButtonClick(Sender: TObject);
var
  path: string;
begin
  if SelectDirectory('选择文件夹', '', path) then
    EditButtonUnpakPath.Text := path;
end;

procedure TMainForm.SetIsLoading(Value: boolean);
begin
  _isLoading := Value;
  if Value then
  begin
    ButtonStart.Enabled := False;
    EditButtonPakPath.Enabled := False;
    EditButtonUnpakPath.Enabled := False;
    RadioButtonPak.Enabled := False;
    RadioButtonUnpak.Enabled := False;
  end
  else
  begin
    ButtonStart.Enabled := True;
    EditButtonPakPath.Enabled := True;
    EditButtonUnpakPath.Enabled := True;
    RadioButtonPak.Enabled := True;
    RadioButtonUnpak.Enabled := True;
  end;
end;

end.

