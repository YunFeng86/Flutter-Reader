// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flutter Reader';

  @override
  String get notFound => '未找到';

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get system => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get language => '语言';

  @override
  String get systemLanguage => '系统语言';

  @override
  String get english => 'English';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get chineseTraditional => '繁體中文';

  @override
  String get reader => '阅读';

  @override
  String get fontSize => '字号';

  @override
  String get lineHeight => '行高';

  @override
  String get horizontalPadding => '左右边距';

  @override
  String get storage => '存储';

  @override
  String get clearImageCache => '清理图片缓存';

  @override
  String get clearImageCacheSubtitle => '移除离线阅读预取的图片缓存';

  @override
  String get cacheCleared => '缓存已清理';

  @override
  String get subscriptions => '订阅';

  @override
  String get all => '全部';

  @override
  String get uncategorized => '未分类';

  @override
  String get refreshAll => '刷新全部';

  @override
  String get refreshSelected => '刷新当前';

  @override
  String get importOpml => '导入 OPML';

  @override
  String get exportOpml => '导出 OPML';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get newCategory => '新建分类';

  @override
  String get articles => '文章';

  @override
  String get unread => '未读';

  @override
  String get markAllRead => '全部已读';

  @override
  String get fullText => '阅读全文';

  @override
  String get readerSettings => '阅读设置';

  @override
  String get done => '完成';

  @override
  String get more => '更多';

  @override
  String get showAll => '显示全部';

  @override
  String get unreadOnly => '只看未读';

  @override
  String get selectAnArticle => '请选择一篇文章';

  @override
  String errorMessage(String error) {
    return '错误：$error';
  }

  @override
  String unreadCountError(String error) {
    return '未读数获取失败：$error';
  }

  @override
  String get refreshed => '已刷新';

  @override
  String get refreshedAll => '全部已刷新';

  @override
  String get add => '添加';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get delete => '删除';

  @override
  String get deleted => '已删除';

  @override
  String get rssAtomUrl => 'RSS/Atom 地址';

  @override
  String get name => '名称';

  @override
  String get addedAndSynced => '已添加并同步';

  @override
  String get deleteSubscription => '删除订阅';

  @override
  String get deleteSubscriptionConfirmTitle => '删除订阅？';

  @override
  String get deleteSubscriptionConfirmContent => '这也会删除其缓存的文章。';

  @override
  String get deleteCategory => '删除分类';

  @override
  String get categoryDeleted => '分类已删除';

  @override
  String get refresh => '刷新';

  @override
  String get moveToCategory => '移动到分类';

  @override
  String get noFeedsFoundInOpml => 'OPML 中未找到订阅';

  @override
  String importedFeeds(int count) {
    return '已导入 $count 个订阅';
  }

  @override
  String get exportedOpml => '已导出 OPML';

  @override
  String fullTextFailed(String error) {
    return '获取全文失败：$error';
  }

  @override
  String get scrollToLoadMore => '滚动以加载更多';

  @override
  String get noArticles => '暂无文章';

  @override
  String get noUnreadArticles => '暂无未读文章';

  @override
  String get star => '收藏';

  @override
  String get unstar => '取消收藏';

  @override
  String get markRead => '标记为已读';

  @override
  String get markUnread => '标记为未读';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展开';

  @override
  String get search => '搜索';

  @override
  String get groupingAndSorting => '分组与排序';

  @override
  String get rules => '规则';

  @override
  String get services => '服务';

  @override
  String get appPreferences => '应用偏好';

  @override
  String get about => '关于';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Flutter Reader';

  @override
  String get notFound => '未找到';

  @override
  String get settings => '設定';

  @override
  String get appearance => '外觀';

  @override
  String get theme => '主題';

  @override
  String get system => '跟隨系統';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get language => '語言';

  @override
  String get systemLanguage => '系統語言';

  @override
  String get english => 'English';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get chineseTraditional => '繁體中文';

  @override
  String get reader => '閱讀';

  @override
  String get fontSize => '字號';

  @override
  String get lineHeight => '行高';

  @override
  String get horizontalPadding => '左右邊距';

  @override
  String get storage => '儲存';

  @override
  String get clearImageCache => '清理圖片快取';

  @override
  String get clearImageCacheSubtitle => '移除離線閱讀預取的圖片快取';

  @override
  String get cacheCleared => '快取已清理';

  @override
  String get subscriptions => '訂閱';

  @override
  String get all => '全部';

  @override
  String get uncategorized => '未分類';

  @override
  String get refreshAll => '重新整理全部';

  @override
  String get refreshSelected => '重新整理當前';

  @override
  String get importOpml => '匯入 OPML';

  @override
  String get exportOpml => '匯出 OPML';

  @override
  String get addSubscription => '新增訂閱';

  @override
  String get newCategory => '新增分類';

  @override
  String get articles => '文章';

  @override
  String get unread => '未讀';

  @override
  String get markAllRead => '全部已讀';

  @override
  String get fullText => '閱讀全文';

  @override
  String get readerSettings => '閱讀設定';

  @override
  String get done => '完成';

  @override
  String get more => '更多';

  @override
  String get showAll => '顯示全部';

  @override
  String get unreadOnly => '只看未讀';

  @override
  String get selectAnArticle => '請選擇一篇文章';

  @override
  String errorMessage(String error) {
    return '錯誤：$error';
  }

  @override
  String unreadCountError(String error) {
    return '未讀數取得失敗：$error';
  }

  @override
  String get refreshed => '已重新整理';

  @override
  String get refreshedAll => '全部已重新整理';

  @override
  String get add => '新增';

  @override
  String get cancel => '取消';

  @override
  String get create => '建立';

  @override
  String get delete => '刪除';

  @override
  String get deleted => '已刪除';

  @override
  String get rssAtomUrl => 'RSS/Atom 位址';

  @override
  String get name => '名稱';

  @override
  String get addedAndSynced => '已新增並同步';

  @override
  String get deleteSubscription => '刪除訂閱';

  @override
  String get deleteSubscriptionConfirmTitle => '刪除訂閱？';

  @override
  String get deleteSubscriptionConfirmContent => '這也會刪除其快取的文章。';

  @override
  String get deleteCategory => '刪除分類';

  @override
  String get categoryDeleted => '分類已刪除';

  @override
  String get refresh => '重新整理';

  @override
  String get moveToCategory => '移動到分類';

  @override
  String get noFeedsFoundInOpml => 'OPML 中未找到訂閱';

  @override
  String importedFeeds(int count) {
    return '已匯入 $count 個訂閱';
  }

  @override
  String get exportedOpml => '已匯出 OPML';

  @override
  String fullTextFailed(String error) {
    return '取得全文失敗：$error';
  }

  @override
  String get scrollToLoadMore => '捲動以載入更多';

  @override
  String get noArticles => '暫無文章';

  @override
  String get noUnreadArticles => '暫無未讀文章';

  @override
  String get star => '收藏';

  @override
  String get unstar => '取消收藏';

  @override
  String get markRead => '標記為已讀';

  @override
  String get markUnread => '標記為未讀';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展開';
}
