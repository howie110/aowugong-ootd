import '../domain/ootd_filter_state.dart';
import '../domain/ootd_models.dart';
import '../domain/ootd_option_config.dart';

const defaultOotdFilterState = OotdFilterState();
const defaultOotdOptionConfig = OotdOptionConfig();

final defaultMockOotdItems = <MockOotdItem>[
  MockOotdItem(
    id: 'look-01',
    images: [
      MockOotdImage.solid(id: 'look-01-main', colorValue: 0xFFC8D7EB),
      MockOotdImage.solid(id: 'look-01-sub-01', colorValue: 0xFFE8EEF8),
    ],
    dateLabel: '2026-04-05',
    preference: '喜欢',
    season: '春',
    scene: '工作',
    tone: '冷色',
    rating: '5星',
  ),
  MockOotdItem(
    id: 'look-02',
    images: [
      MockOotdImage.solid(id: 'look-02-main', colorValue: 0xFFE7BFA8),
      MockOotdImage.solid(id: 'look-02-sub-01', colorValue: 0xFFF5E4D6),
      MockOotdImage.solid(id: 'look-02-sub-02', colorValue: 0xFFE8D5CA),
    ],
    dateLabel: '2026-04-03',
    preference: '不喜欢',
    season: '夏',
    scene: '休息',
    tone: '暖色',
    rating: '3星',
  ),
  MockOotdItem(
    id: 'look-03',
    images: [
      MockOotdImage.solid(id: 'look-03-main', colorValue: 0xFFD9D9D9),
    ],
    dateLabel: '2026-04-01',
    preference: '喜欢',
    season: '秋',
    scene: '工作',
    tone: '黑白',
    rating: '4星',
  ),
  MockOotdItem(
    id: 'look-04',
    images: [
      MockOotdImage.solid(id: 'look-04-main', colorValue: 0xFFB8CBE5),
      MockOotdImage.solid(id: 'look-04-sub-01', colorValue: 0xFFD5E6FA),
    ],
    dateLabel: '2026-03-30',
    preference: '不喜欢',
    season: '冬',
    scene: '休息',
    tone: '冷色',
    rating: '2星',
  ),
  MockOotdItem(
    id: 'look-05',
    images: [
      MockOotdImage.solid(id: 'look-05-main', colorValue: 0xFFE4BC8F),
      MockOotdImage.solid(id: 'look-05-sub-01', colorValue: 0xFFF4E0C8),
      MockOotdImage.solid(id: 'look-05-sub-02', colorValue: 0xFFEAD0B5),
    ],
    dateLabel: '2026-03-28',
    preference: '喜欢',
    season: '春',
    scene: '工作',
    tone: '暖色',
    rating: '4星',
  ),
  MockOotdItem(
    id: 'look-06',
    images: [
      MockOotdImage.solid(id: 'look-06-main', colorValue: 0xFFCAD1DC),
    ],
    dateLabel: '2026-03-26',
    preference: '喜欢',
    season: '夏',
    scene: '休息',
    tone: '黑白',
    rating: '5星',
  ),
  MockOotdItem(
    id: 'look-07',
    images: [
      MockOotdImage.solid(id: 'look-07-main', colorValue: 0xFFBFD0E5),
      MockOotdImage.solid(id: 'look-07-sub-01', colorValue: 0xFFDDE8F5),
    ],
    dateLabel: '2026-03-24',
    preference: '不喜欢',
    season: '秋',
    scene: '工作',
    tone: '冷色',
    rating: '1星',
  ),
  MockOotdItem(
    id: 'look-08',
    images: [
      MockOotdImage.solid(id: 'look-08-main', colorValue: 0xFFE8BE95),
      MockOotdImage.solid(id: 'look-08-sub-01', colorValue: 0xFFF7DFC9),
      MockOotdImage.solid(id: 'look-08-sub-02', colorValue: 0xFFEED0AA),
    ],
    dateLabel: '2026-03-22',
    preference: '喜欢',
    season: '冬',
    scene: '休息',
    tone: '暖色',
    rating: '3星',
  ),
  MockOotdItem(
    id: 'look-09',
    images: [
      MockOotdImage.solid(id: 'look-09-main', colorValue: 0xFFC6C9D1),
      MockOotdImage.solid(id: 'look-09-sub-01', colorValue: 0xFFE4E6EB),
    ],
    dateLabel: '2026-03-20',
    preference: '喜欢',
    season: '春',
    scene: '休息',
    tone: '黑白',
    rating: '4星',
  ),
];
