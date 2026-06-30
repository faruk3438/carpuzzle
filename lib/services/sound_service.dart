import 'package:audioplayers/audioplayers.dart';

/// Oyun ses efektleri ve müzik yöneticisi.
class SoundService {
  static final SoundService _instance = SoundService._();
  static SoundService get instance => _instance;
  SoundService._();

  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _vehiclePlayer = AudioPlayer();
  final AudioPlayer _impactPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _sfxEnabled = true;
  bool _bgmEnabled = true;

  bool get sfxEnabled => _sfxEnabled;
  bool get bgmEnabled => _bgmEnabled;

  Future<void> init() async {
    await _uiPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _vehiclePlayer.setPlayerMode(PlayerMode.lowLatency);
    await _impactPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // ─── Ses Efektleri ────────────────────────────────────────────────────────

  Future<void> playTap() => _playUi('sounds/tap.mp3', volume: 0.55);

  Future<void> playCarMove() =>
      _playVehicle('sounds/car_slide.wav', volume: 0.68);

  Future<void> playCarExit() =>
      _playVehicle('sounds/car_whoosh.wav', volume: 0.32);

  Future<void> playCarCrash({bool heavy = true}) =>
      _playImpact('sounds/car_crash.wav', volume: heavy ? 0.95 : 0.56);

  Future<void> playCombo() => _playUi('sounds/combo.mp3');

  Future<void> playWin() => _playUi('sounds/win.mp3');

  Future<void> playFail() => _playUi('sounds/fail.mp3');

  Future<void> playDeadlock() => _playImpact('sounds/deadlock.mp3');

  Future<void> playStarCollect() => _playUi('sounds/star.mp3');

  Future<void> playButtonClick() => _playUi('sounds/click.mp3');

  Future<void> _playUi(String path, {double volume = 1.0}) =>
      _playSfx(_uiPlayer, path, volume: volume);

  Future<void> _playVehicle(String path, {double volume = 1.0}) =>
      _playSfx(_vehiclePlayer, path, volume: volume);

  Future<void> _playImpact(String path, {double volume = 1.0}) =>
      _playSfx(_impactPlayer, path, volume: volume);

  Future<void> _playSfx(
    AudioPlayer player,
    String path, {
    double volume = 1.0,
  }) async {
    if (!_sfxEnabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(path), volume: volume);
    } catch (_) {
      // Placeholder or unsupported files should never interrupt gameplay.
    }
  }

  // ─── Arka Plan Müziği ────────────────────────────────────────────────────

  Future<void> playBgm(String path) async {
    if (!_bgmEnabled) return;
    await _bgmPlayer.stop();
    await _bgmPlayer.play(AssetSource(path));
  }

  Future<void> stopBgm() => _bgmPlayer.stop();

  Future<void> pauseBgm() => _bgmPlayer.pause();

  Future<void> resumeBgm() => _bgmPlayer.resume();

  // ─── Ayarlar ─────────────────────────────────────────────────────────────

  void toggleSfx() => _sfxEnabled = !_sfxEnabled;
  void toggleBgm() {
    _bgmEnabled = !_bgmEnabled;
    if (!_bgmEnabled) {
      _bgmPlayer.stop();
    }
  }

  void dispose() {
    _uiPlayer.dispose();
    _vehiclePlayer.dispose();
    _impactPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
