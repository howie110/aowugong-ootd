import 'package:aowugong_ootd/shared/design/app_ui.dart';
import '../../../../app/app_metadata.dart';

class SettingsInformationPage extends StatelessWidget {
  const SettingsInformationPage({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppPageBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Text(
            title == '版本信息'
                ? '每日穿搭 $appFullVersion\n\n照片和记录只保存在本机。应用无需账号，不上传照片。'
                : '记录穿搭\n每天记录一套穿搭，最多添加 4 张图片。点击图片预览，使用替换按钮更换图片。\n\n筛选与选项\n首页可同时选择多个筛选条件。在选项管理中添加、修改或删除内容。\n\n备份与换机\n在数据备份中导出 ZIP，保存到你能找到的位置。将 ZIP 复制到新手机后，在备份导入中选择它。导入会替换当前记录，请先备份。\n\n照片与空间\n选择的照片会复制到应用本地目录。卸载应用或清除应用数据会移除这些副本，请定期导出备份。',
          ),
        ),
      ],
    ),
  );
}
