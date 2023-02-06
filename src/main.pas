unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  P;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonStart: TButton;
    EditButtonPakPath: TEditButton;
    EditButtonUnpakPath: TEditButton;
    Label1: TLabel;
    Label2: TLabel;
    RadioButtonUnpak: TRadioButton;
    RadioButtonPak: TRadioButton;
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
  pakPath: string;
  unpakPath: string;
begin
  pakPath := Trim(EditButtonPakPath.Text);
  unpakPath := Trim(EditButtonUnpakPath.Text);

  if pakPath = '' then
  begin
    ShowMessage('请输入pak文件路径');
    exit;
  end;
  if unpakPath = '' then
  begin
    ShowMessage('解包/打包路径不能为空');
    exit;
  end;

  if RadioButtonPak.Checked then
  begin
    SetIsLoading(True);
    if Pak(unpakPath, pakPath) then
      ShowMessage('打包完成')
    else
      ShowErrorMessage;
    SetIsLoading(False);
  end
  else if RadioButtonUnpak.Checked then
  begin
    SetIsLoading(True);
    if Unpak(pakPath, unpakPath) then
      ShowMessage('解包完成')
    else
      ShowErrorMessage;
    SetIsLoading(False);
  end;
end;

procedure TMainForm.EditButtonInputButtonClick(Sender: TObject);
var
  sd: TSaveDialog;
begin
  sd := TSaveDialog.Create(self);
  sd.Title := '选择文件';
  sd.Filter := 'pak文件|*.pak';
  sd.FileName := 'main';
  if sd.Execute then
    EditButtonPakPath.Text := sd.FileName;
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
    RadioButtonUnpak.Enabled := False;
    RadioButtonPak.Enabled := False;
    if RadioButtonUnpak.Checked then
      ButtonStart.Caption := '解包中...'
    else if RadioButtonPak.Checked then
      ButtonStart.Caption := '打包中...';
  end
  else
  begin
    ButtonStart.Enabled := True;
    EditButtonPakPath.Enabled := True;
    EditButtonUnpakPath.Enabled := True;
    RadioButtonUnpak.Enabled := True;
    RadioButtonPak.Enabled := True;
    ButtonStart.Caption := '执行';
  end;
end;

end.
