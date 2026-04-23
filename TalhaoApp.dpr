program TalhaoApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  models in 'units\models.pas',
  view.cadastro.talhao.web in 'forms\view.cadastro.talhao.web.pas' {ViewCadastroTalhao},
  view.consulta.talhao in 'forms\view.consulta.talhao.pas' {viewConsultaTalhao},
  view.main in 'forms\view.main.pas' {frmMain},
  view.cadastro.talhao.map in 'forms\view.cadastro.talhao.map.pas' {ViewCadastroTalhaoMap},
  model.con in 'model\model.con.pas' {dmCon: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TdmCon, dmCon);
  Application.Run;
end.
