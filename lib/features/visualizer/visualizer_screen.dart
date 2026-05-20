import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/audio_provider.dart';

// ─── Beat Engine ──────────────────────────────────────────────────────────────

class BeatEngine {
  static const _bpm  = 128.0;
  static const _stepMs = (60000.0 / _bpm) / 4.0; // 16th note

  // 16-step drum patterns
  static const _kick  = [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0];
  static const _snare = [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0];
  static const _hihat = [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0];
  static const _bass  = [1,0,0,1, 0,0,1,0, 1,0,0,1, 0,1,0,0];

  int    step      = 0;
  double stepTimer = 0;
  double kick      = 0;
  double snare     = 0;
  double hihat     = 0;
  double bassHit   = 0;
  double impact    = 0;   // combined beat impact for edge glow
  double time      = 0;

  // 32-bin spectrum
  final spectrum  = Float64List(32);
  final _specPrev = Float64List(32);
  final peakHold  = Float64List(32);
  final _peakTimer= Float64List(32);

  // Smoothed energy bands
  double sub=0, bass=0, mid=0, highmid=0, treble=0;

  void update(double dtMs) {
    time    += dtMs * 0.001;
    stepTimer += dtMs;

    if (stepTimer >= _stepMs) {
      stepTimer -= _stepMs;
      step = (step + 1) % 16;
      if (_kick [step] > 0) kick  = 1.0 * _kick [step];
      if (_snare[step] > 0) snare = 0.85* _snare[step];
      if (_hihat[step] > 0) hihat = 0.55* _hihat[step];
      if (_bass [step] > 0) bassHit=0.7 * _bass [step];
    }

    // Decay flashes
    kick    = math.max(0, kick    - dtMs * 0.006);
    snare   = math.max(0, snare   - dtMs * 0.007);
    hihat   = math.max(0, hihat   - dtMs * 0.010);
    bassHit = math.max(0, bassHit - dtMs * 0.005);
    impact  = math.max(0, impact  - dtMs * 0.005);
    if (_kick[step] > 0 && stepTimer < 60) impact = 1.0;
    else if (_snare[step] > 0 && stepTimer < 60) impact = math.max(impact, 0.6);

    // Generate 32-bin spectrum from drum state
    for (int i = 0; i < 32; i++) {
      final f = i / 31.0;
      double v = 0.03 + 0.04 * (math.sin(time*0.5 + i*0.7)).abs();

      if (i < 3)       v += kick *(0.8 - i*0.15) + 0.1*bassHit*(math.sin(time*1.2)).abs();
      else if (i < 8)  v += kick *0.5*(1-(i-3)/5.0) + snare*0.15 + 0.08*(math.sin(time*1.5+i)).abs();
      else if (i < 14) v += snare*0.4*(1-(i-8)/6.0) + kick*0.1  + 0.10*(math.sin(time*2.1+i*0.5)).abs();
      else if (i < 20) v += snare*0.3 + 0.12*(math.sin(time*3.0+i*0.4)).abs();
      else if (i < 26) v += hihat*0.45*(1-(i-20)/6.0) + snare*0.2 + 0.08*(math.sin(time*4.2+i*0.3)).abs();
      else             v += hihat*0.65 + 0.06*(math.sin(time*6.0+i*0.2)).abs();

      spectrum[i] = _specPrev[i]*0.72 + v*0.28;
      _specPrev[i] = spectrum[i];

      _peakTimer[i] = math.max(0, _peakTimer[i] - dtMs);
      if (spectrum[i] > peakHold[i] || _peakTimer[i] <= 0) {
        peakHold[i] = spectrum[i];
        _peakTimer[i] = 1200;
      }
      peakHold[i] = math.max(spectrum[i], peakHold[i] - dtMs*0.0003);
    }

    // Smooth energy bands
    double s(int a, int b){double v=0;for(int i=a;i<=b;i++)v+=spectrum[i];return v/(b-a+1);}
    const sm=0.15;
    sub     = sub     *(1-sm) + s(0,2)  *sm;
    bass    = bass    *(1-sm) + s(3,7)  *sm;
    mid     = mid     *(1-sm) + s(8,19) *sm;
    highmid = highmid *(1-sm) + s(20,25)*sm;
    treble  = treble  *(1-sm) + s(26,31)*sm;
  }
}

// ─── Burst Particle ───────────────────────────────────────────────────────────

class _Burst {
  late double x, y, vx, vy, r, life, maxLife, hue;
  _Burst(double cx, double cy, double strength) {
    final a = math.Random().nextDouble() * math.pi * 2;
    final sp = (2 + math.Random().nextDouble()*6)*strength;
    x=cx; y=cy; vx=math.cos(a)*sp; vy=math.sin(a)*sp;
    r=1+math.Random().nextDouble()*3*strength;
    life=0; maxLife=0.4+math.Random().nextDouble()*0.6;
    hue=180+math.Random().nextDouble()*80;
  }
  bool update(double dt){ x+=vx; y+=vy; vx*=0.92; vy=vy*0.92+0.05; life+=dt/1000; return life<maxLife; }
}

// ─── Plasma Wave Painter ──────────────────────────────────────────────────────

class _PlasmaPainter extends CustomPainter {
  final BeatEngine beat;
  final double t;
  _PlasmaPainter(this.beat, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final W=size.width, H=size.height;
    // Background
    canvas.drawRect(Rect.fromLTWH(0,0,W,H),
        Paint()..shader=LinearGradient(colors:const[Color(0xFF080810),Color(0xFF04040A)],
            begin:Alignment.topCenter,end:Alignment.bottomCenter)
            .createShader(Rect.fromLTWH(0,0,W,H)));

    final cy=H*0.48;
    final amp=60+beat.bass*180+beat.kick*100;

    for (int layer=3; layer>=0; layer--) {
      final layerAmp=amp*(1-layer*0.2)*(0.3+layer*0.2);
      final alpha=0.06+(3-layer)*0.06+(layer==0?beat.sub*0.3:0);
      final hue=210.0+layer*15-beat.kick*30+beat.snare*20;

      final path=Path();
      final fillPath=Path();
      fillPath.moveTo(0,cy);

      for (double x=0; x<=W; x+=2) {
        final p=x/W;
        final warp=math.sin(p*math.pi);
        final lt=t-layer*0.12;
        double y=cy;
        y+=layerAmp*0.6*math.sin(p*math.pi*3+lt*2.1)*warp;
        y+=layerAmp*0.3*math.sin(p*math.pi*5+lt*3.3+math.pi/4)*warp;
        y+=beat.kick*40*math.sin(p*math.pi)*math.sin(t*8);
        y+=beat.snare*25*math.sin(p*math.pi*7+t*5)*warp*0.5;
        y+=beat.treble*20*math.sin(p*math.pi*12+t*8)*warp*0.3;

        if(x==0){path.moveTo(x,y);fillPath.lineTo(x,y);}
        else {path.lineTo(x,y);fillPath.lineTo(x,y);}
      }
      fillPath.lineTo(W,H); fillPath.lineTo(0,H); fillPath.close();

      final lit=(70.0+layer*8)/100.0;
      final fillPaint=Paint()
        ..shader=LinearGradient(
          colors:[
            HSLColor.fromAHSL(alpha*1.5, hue, 0.25, lit).toColor(),
            HSLColor.fromAHSL(alpha*0.5, hue, 0.20, lit-0.1).toColor(),
            Colors.transparent,
          ],
          stops:const[0.0,0.4,1.0],
          begin:Alignment.topCenter, end:Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0,cy-amp,W,H));
      canvas.drawPath(fillPath, fillPaint);

      if (layer==0) {
        final hueC=HSLColor.fromAHSL(1.0,hue,0.25,0.9).toColor();
        final strokePaint=Paint()
          ..shader=LinearGradient(
            colors:[hueC.withOpacity(0.1),hueC.withOpacity(0.9),Colors.white.withOpacity(0.95),hueC.withOpacity(0.9),hueC.withOpacity(0.1)],
            stops:const[0.0,0.2,0.5,0.8,1.0],
          ).createShader(Rect.fromLTWH(0,0,W,0))
          ..style=PaintingStyle.stroke
          ..strokeWidth=1.8+beat.bass*2+beat.kick
          ..strokeCap=StrokeCap.round
          ..maskFilter=MaskFilter.blur(BlurStyle.normal,4+beat.kick*16+beat.bass*12);
        canvas.drawPath(path,strokePaint);
      }
    }
  }

  @override bool shouldRepaint(_PlasmaPainter o)=>true;
}

// ─── Radial Burst Painter ─────────────────────────────────────────────────────

class _RadialPainter extends CustomPainter {
  final BeatEngine beat;
  final double t;
  final List<_Burst> bursts;
  _RadialPainter(this.beat, this.t, this.bursts);

  @override
  void paint(Canvas canvas, Size size) {
    final W=size.width, H=size.height;
    final cx=W/2, cy=H*0.44;
    canvas.drawRect(Rect.fromLTWH(0,0,W,H),Paint()..color=const Color(0xFF070710));

    final baseR=70+beat.bass*50+beat.kick*40;

    // Halo on kick
    if (beat.kick>0.3) {
      canvas.drawCircle(Offset(cx,cy), baseR+90+beat.kick*60,
        Paint()..shader=RadialGradient(colors:[
          Colors.white.withOpacity(beat.kick*0.2),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center:Offset(cx,cy),radius:baseR+90+beat.kick*60)));
    }

    // Spectrum bars
    const n=64;
    for (int i=0;i<n;i++) {
      final angle=(i/n)*math.pi*2 - math.pi/2 + t*0.05;
      final bin=(i/n*31).floor();
      final val=beat.spectrum[bin]*(1+beat.kick*0.8);
      final barH=5+val*160;
      final peak=beat.peakHold[bin]*185+5;

      final hue=200.0+(i/n)*80+beat.snare*40;
      final barC=HSLColor.fromAHSL((0.5+val*1.2).clamp(0,1),hue,0.25,0.88).toColor();

      final x1=cx+baseR*math.cos(angle);
      final y1=cy+baseR*math.sin(angle);
      final x2=cx+(baseR+barH)*math.cos(angle);
      final y2=cy+(baseR+barH)*math.sin(angle);
      final xp=cx+(baseR+peak+2)*math.cos(angle);
      final yp=cy+(baseR+peak+2)*math.sin(angle);

      canvas.drawLine(Offset(x1,y1),Offset(x2,y2),
          Paint()..color=barC..strokeWidth=2.5+beat.kick
            ..strokeCap=StrokeCap.round
            ..maskFilter=MaskFilter.blur(BlurStyle.normal,3+val*8+beat.kick*5));
      canvas.drawCircle(Offset(xp,yp),1.5,
          Paint()..color=HSLColor.fromAHSL(0.6+val*0.5,hue,0.3,0.98).toColor());
    }

    // Center orb
    canvas.drawCircle(Offset(cx,cy),baseR-10,
        Paint()..shader=RadialGradient(colors:[
          Colors.white.withOpacity(0.06+beat.kick*0.1),
          Colors.white.withOpacity(0.02+beat.bass*0.05),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center:Offset(cx,cy),radius:baseR)));

    // Ring border
    canvas.drawCircle(Offset(cx,cy),baseR,
        Paint()..color=Colors.white.withOpacity(0.08+beat.kick*0.15+beat.sub*0.1)
          ..style=PaintingStyle.stroke..strokeWidth=1);

    // Burst particles
    for (final b in bursts) {
      final a=(1-(b.life/b.maxLife)).clamp(0.0,1.0);
      canvas.drawCircle(Offset(b.x,b.y),b.r,
          Paint()..color=HSLColor.fromAHSL(a,b.hue,0.25,0.9).toColor());
    }
  }

  @override bool shouldRepaint(_RadialPainter o)=>true;
}

// ─── Beat Bars Painter ────────────────────────────────────────────────────────

class _BarsPainter extends CustomPainter {
  final BeatEngine beat;
  final double t;
  _BarsPainter(this.beat, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final W=size.width, H=size.height;
    const n=32;
    final bottomY=H*0.72;
    final maxH=bottomY-60.0;
    final barW=(W-36)/n;

    canvas.drawRect(Rect.fromLTWH(0,0,W,H),Paint()..color=const Color(0xFF060608));

    // Grid
    for (int g=0;g<=4;g++) {
      final gy=bottomY-g*(maxH/4);
      canvas.drawLine(Offset(18,gy),Offset(W-18,gy),
          Paint()..color=Colors.white.withOpacity(0.03)..strokeWidth=0.5);
    }

    for (int i=0;i<n;i++) {
      final x=18+i*barW;
      final val=beat.spectrum[i];
      final barH=math.max(3.0, val*maxH);
      final peak=math.max(3.0, beat.peakHold[i]*maxH);
      final top=bottomY-barH;
      final peakY=bottomY-peak-2;

      final hue=210.0+(i/n)*60+beat.kick*(-20)+beat.snare*30;
      final sat=0.15+val*0.35+beat.kick*0.2;
      final lit=0.65+val*0.25+beat.kick*0.15;
      final alpha=(0.5+val*0.7).clamp(0.0,1.0);

      final topC=HSLColor.fromAHSL((alpha*1.1).clamp(0,1),hue,sat+0.1,lit+0.1).toColor();
      final midC=HSLColor.fromAHSL(alpha,hue,sat,lit).toColor();
      final botC=HSLColor.fromAHSL(alpha*0.7,hue-10,(sat-0.05).clamp(0,1),(lit-0.2).clamp(0,1)).toColor();

      final bw=barW-2;
      final rect=Rect.fromLTWH(x,top,bw,barH);
      final rRect=RRect.fromRectAndCorners(rect,topLeft:const Radius.circular(2),topRight:const Radius.circular(2));

      // Bar with glow
      canvas.drawRRect(rRect,
          Paint()
            ..shader=LinearGradient(colors:[topC,midC,botC],
                stops:const[0.0,0.5,1.0],
                begin:Alignment.topCenter,end:Alignment.bottomCenter)
              .createShader(rect)
            ..maskFilter=MaskFilter.blur(BlurStyle.normal,3+val*10+beat.kick*8));

      // Top highlight
      canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTWH(x,top,bw,3),
              topLeft:const Radius.circular(2),topRight:const Radius.circular(2)),
          Paint()..color=HSLColor.fromAHSL(0.4+val*0.4,hue,sat+0.05,lit+0.2).toColor());

      // Right highlight (3D face)
      canvas.drawRect(Rect.fromLTWH(x+bw-2,top,2,barH),
          Paint()..color=HSLColor.fromAHSL(0.12+val*0.15,hue,sat,(lit+0.15).clamp(0,1)).toColor());

      // Peak line
      if (peak>4) {
        canvas.drawRect(Rect.fromLTWH(x,peakY,bw,2),
            Paint()..color=HSLColor.fromAHSL(0.85,hue,sat+0.1,lit+0.2).toColor());
      }

      // Mirror
      canvas.drawRect(Rect.fromLTWH(x,bottomY,bw,math.min(40,barH*0.25)),
          Paint()..shader=LinearGradient(
            colors:[HSLColor.fromAHSL(alpha*0.18,hue,sat,lit).toColor(),Colors.transparent],
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x,bottomY,bw,40)));
    }

    // Bottom line
    canvas.drawLine(Offset(18,bottomY),Offset(W-18,bottomY),
        Paint()..color=Colors.white.withOpacity(0.05+beat.kick*0.1)..strokeWidth=1);

    // Kick flash overlay
    if (beat.kick>0.4) {
      canvas.drawRect(Rect.fromLTWH(0,0,W,H),
          Paint()..shader=RadialGradient(
            center:Alignment.bottomCenter, radius:1.2,
            colors:[Colors.white.withOpacity(beat.kick*0.07),Colors.transparent],
          ).createShader(Rect.fromLTWH(0,0,W,H)));
    }
  }

  @override bool shouldRepaint(_BarsPainter o)=>true;
}

// ─── Nebula Painter ───────────────────────────────────────────────────────────

class _NebulaPainter extends CustomPainter {
  final BeatEngine beat;
  final double t;
  final List<_Burst> bursts;
  _NebulaPainter(this.beat, this.t, this.bursts);

  @override
  void paint(Canvas canvas, Size size) {
    final W=size.width, H=size.height;
    final cx=W/2, cy=H*0.44;

    // Fade trail
    canvas.drawRect(Rect.fromLTWH(0,0,W,H),
        Paint()..color=const Color(0xFF040408).withOpacity(0.28));

    // Nebula cloud layers
    for (int layer=0;layer<3;layer++) {
      final cloudR=60+layer*35.0+beat.bass*40+beat.kick*30;
      final hue=200.0+layer*25+beat.snare*30;
      final lx=cx+math.sin(t*0.3+layer)*20;
      final ly=cy+math.cos(t*0.2+layer)*15;
      canvas.drawCircle(Offset(cx,cy),cloudR+40+layer*20,
          Paint()..shader=RadialGradient(
            center:Alignment((lx-cx)/W,(ly-cy)/H),
            radius:1.0,
            colors:[
              HSLColor.fromAHSL((0.03+beat.sub*0.06)*2,hue,0.3,0.8).toColor(),
              HSLColor.fromAHSL(0.03+beat.sub*0.06,hue+20,0.25,0.7).toColor(),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center:Offset(cx,cy),radius:cloudR+60+layer*20)));
    }

    // Orbit rings
    for (int ring=0;ring<3;ring++) {
      final r=50+ring*30.0+beat.mid*30;
      final speed=(ring+1)*0.15+beat.kick*0.5;
      final pCount=16+ring*8;
      final hue=200.0+ring*30+beat.snare*40;

      for (int i=0;i<pCount;i++) {
        final angle=t*speed+(i/pCount)*math.pi*2;
        final pulse=0.6+0.4*math.sin(t*3+i*0.7+ring).abs();
        final bin=(i/pCount*31).floor();
        final pr=r+pulse*12+beat.spectrum[bin]*25;
        final px=cx+pr*math.cos(angle);
        final py=cy+pr*math.sin(angle);
        final ps=1+pulse*2+beat.spectrum[bin]*3;
        final a=(0.3+pulse*0.5+beat.spectrum[bin]*0.4).clamp(0.0,1.0);

        canvas.drawCircle(Offset(px,py),ps,
            Paint()
              ..color=HSLColor.fromAHSL(a,hue+i*3.0,0.25,0.92).toColor()
              ..maskFilter=MaskFilter.blur(BlurStyle.normal,2+pulse*5+beat.kick*6));
      }
    }

    // Burst particles
    for (final b in bursts) {
      final a=(1-(b.life/b.maxLife)).clamp(0.0,1.0);
      canvas.drawCircle(Offset(b.x,b.y),b.r,
          Paint()..color=HSLColor.fromAHSL(a,b.hue,0.25,0.9).toColor());
    }

    // Center orb
    final orbR=22+beat.bass*18+beat.kick*15;
    canvas.drawCircle(Offset(cx,cy),orbR,
        Paint()
          ..shader=RadialGradient(colors:[
            Colors.white.withOpacity(0.3+beat.kick*0.4),
            Colors.white.withOpacity(0.15+beat.bass*0.2),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center:Offset(cx,cy),radius:orbR))
          ..maskFilter=MaskFilter.blur(BlurStyle.normal,12+beat.kick*22+beat.bass*14));

    // Cross flare on kick
    if (beat.kick>0.5) {
      final flareLen=80+beat.kick*120;
      for (int a=0;a<4;a++) {
        final angle=a*math.pi/2+t*0.1;
        final ex=cx+math.cos(angle)*flareLen;
        final ey=cy+math.sin(angle)*flareLen;
        canvas.drawLine(Offset(cx,cy),Offset(ex,ey),
            Paint()
              ..shader=LinearGradient(
                colors:[Colors.white.withOpacity(beat.kick*0.6),Colors.transparent],
              ).createShader(Rect.fromPoints(Offset(cx,cy),Offset(ex,ey)))
              ..strokeWidth=1.5+beat.kick
              ..strokeCap=StrokeCap.round);
      }
    }
  }

  @override bool shouldRepaint(_NebulaPainter o)=>true;
}

// ─── Edge Lighting Painter ────────────────────────────────────────────────────

class _EdgeLightPainter extends CustomPainter {
  final BeatEngine beat;
  final double rotation;
  _EdgeLightPainter(this.beat, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    if (beat.impact < 0.05 && beat.sub < 0.05) return;
    final W=size.width, H=size.height;
    final r=RRect.fromRectAndRadius(
        Rect.fromLTWH(-4,-4,W+8,H+8),const Radius.circular(48));

    final hue=220.0+beat.snare*60-beat.kick*40;
    final sat=(0.15+beat.impact*0.55).clamp(0.0,1.0);
    final alpha=(0.08+beat.impact*0.55).clamp(0.0,0.9);

    // Sweeping arc glow using shadow paint
    canvas.drawRRect(r,
        Paint()
          ..color=Colors.transparent
          ..style=PaintingStyle.stroke
          ..strokeWidth=4+beat.impact*12
          ..maskFilter=MaskFilter.blur(BlurStyle.normal,8+beat.impact*20)
          ..shader=SweepGradient(
            startAngle:rotation,
            endAngle:rotation+math.pi*2,
            colors:[
              HSLColor.fromAHSL(alpha*1.2,hue,sat,0.88).toColor(),
              HSLColor.fromAHSL(alpha*0.4,hue+60,sat,0.9).toColor(),
              HSLColor.fromAHSL(alpha*0.8,hue+120,sat,0.85).toColor(),
              HSLColor.fromAHSL(alpha*0.3,hue+180,sat,0.88).toColor(),
              HSLColor.fromAHSL(alpha*1.2,hue,sat,0.88).toColor(),
            ],
          ).createShader(Rect.fromLTWH(-4,-4,W+8,H+8)));
  }

  @override bool shouldRepaint(_EdgeLightPainter o)=>true;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class VisualizerScreen extends ConsumerStatefulWidget {
  const VisualizerScreen({super.key});

  @override
  ConsumerState<VisualizerScreen> createState() => _VisualizerScreenState();
}

class _VisualizerScreenState extends ConsumerState<VisualizerScreen>
    with TickerProviderStateMixin {

  late AnimationController _ticker;
  final _beat = BeatEngine();
  final _bursts = <_Burst>[];
  int _mode = 0;
  double _edgeRotation = 0;
  double _lastT = 0;

  // Tap tempo
  final List<int> _tapTimes = [];
  int _bpm = 128;

  static const _modes = [
    _ModeInfo('🌊','Plasma',  'Fluid wave morphing to every beat'),
    _ModeInfo('⭕','Radial',  'Circular spectrum, star-burst on kick'),
    _ModeInfo('✦','Bars',    '3D-lit bars with bloom and peak trails'),
    _ModeInfo('✨','Nebula',  'Particle galaxy exploding on beat'),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync:this, duration:const Duration(seconds:600))..repeat();
    _ticker.addListener(_onTick);
  }

  void _onTick() {
    final t = _ticker.value * 600000; // ms
    final dt = (t - _lastT).clamp(0.0, 50.0);
    _lastT = t;

    _beat.update(dt);
    _edgeRotation += 0.003 + _beat.impact * 0.015;

    // Kick bursts for radial/nebula modes
    if (_beat.kick > 0.8 && _beat.stepTimer < 50 && (_mode==1||_mode==3)) {
      final cx = MediaQuery.of(context).size.width / 2;
      final cy = MediaQuery.of(context).size.height * 0.44;
      for (int i=0;i<20;i++) _bursts.add(_Burst(cx,cy,_beat.kick*0.8));
    }
    _bursts.removeWhere((b)=>!b.update(dt));

    setState((){});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _tapTimes.add(now);
    final recent = _tapTimes.where((t)=>now-t<4000).toList();
    _tapTimes.clear(); _tapTimes.addAll(recent);
    if (recent.length >= 2) {
      double sum=0;
      for(int i=1;i<recent.length;i++) sum+=recent[i]-recent[i-1];
      setState(()=>_bpm=(60000/(sum/(recent.length-1))).round());
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ────────────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20,14,20,0),
            child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Live FFT', style:AppTextStyles.labelMedium
                  .copyWith(color:AppColors.textTertiary,letterSpacing:1.2)),
              const SizedBox(height:4),
              const Text('Visualizer', style:AppTextStyles.headlineMedium),
              const SizedBox(height:2),
              Text('Beat-aware · Edge lighting · 4 modes',
                  style:AppTextStyles.bodySmall.copyWith(color:AppColors.textTertiary)),
            ]),
          ),
        ),

        // ── Mode selector ──────────────────────────────────────────────────
        Padding(
          padding:const EdgeInsets.fromLTRB(20,14,20,0),
          child:Row(children:List.generate(_modes.length,(i){
            final sel=_mode==i;
            return Expanded(child:GestureDetector(
              onTap:()=>setState(()=>_mode=i),
              child:AnimatedContainer(
                duration:const Duration(milliseconds:200),
                margin:EdgeInsets.only(right:i<_modes.length-1?8:0),
                padding:const EdgeInsets.symmetric(vertical:9),
                decoration:BoxDecoration(
                  color:sel?AppColors.primary.withOpacity(0.12):AppColors.surface,
                  borderRadius:BorderRadius.circular(11),
                  border:Border.all(
                    color:sel?AppColors.primary.withOpacity(0.4):AppColors.border,
                    width:sel?1.0:0.5),
                ),
                child:Column(children:[
                  Text(_modes[i].icon, style:const TextStyle(fontSize:16)),
                  const SizedBox(height:3),
                  Text(_modes[i].label,style:TextStyle(
                    fontFamily:'Inter',fontSize:9,fontWeight:FontWeight.w700,
                    color:sel?AppColors.primary:AppColors.textTertiary)),
                ]),
              ),
            ));
          })),
        ),

        const SizedBox(height:12),

        // ── Visualizer canvas with edge lighting ───────────────────────────
        Expanded(
          child:Padding(
            padding:const EdgeInsets.symmetric(horizontal:20),
            child:ClipRRect(
              borderRadius:BorderRadius.circular(20),
              child:Stack(children:[
                // Edge lighting (behind canvas)
                Positioned.fill(child:CustomPaint(
                  painter:_EdgeLightPainter(_beat,_edgeRotation))),
                // Main visualizer
                Positioned.fill(child:ClipRRect(
                  borderRadius:BorderRadius.circular(18),
                  child:_buildCanvas(size),
                )),
                // Song info overlay
                Positioned(top:14,left:16,right:16,
                  child:Row(children:[
                    _LiveDot(beat:_beat),
                    const SizedBox(width:8),
                    Expanded(child:Text(
                      song!=null?'${song.title} — ${song.artist}':'Play something to see motion',
                      style:const TextStyle(fontFamily:'Inter',fontSize:11,
                          color:AppColors.textSecondary),
                      maxLines:1,overflow:TextOverflow.ellipsis)),
                  ])),
                // IDLE badge
                if (!playerState.isPlaying)
                  Positioned(bottom:14,left:0,right:0,
                    child:Center(child:Container(
                      padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),
                      decoration:BoxDecoration(
                        color:AppColors.surfaceVariant,
                        borderRadius:BorderRadius.circular(20),
                        border:Border.all(color:AppColors.border,width:0.5)),
                      child:Row(mainAxisSize:MainAxisSize.min,children:[
                        Container(width:6,height:6,decoration:BoxDecoration(
                          shape:BoxShape.circle,color:AppColors.textTertiary)),
                        const SizedBox(width:6),
                        const Text('IDLE',style:TextStyle(fontFamily:'Inter',
                            fontSize:9,fontWeight:FontWeight.w700,
                            color:AppColors.textTertiary,letterSpacing:2)),
                      ]),
                    ))),
              ]),
            ),
          ),
        ),

        // ── Mini spectrum + BPM row ────────────────────────────────────────
        Padding(
          padding:const EdgeInsets.fromLTRB(20,10,20,0),
          child:Row(children:[
            // Mini 16-bar spectrum
            Expanded(child:Container(
              height:38,
              decoration:BoxDecoration(
                color:AppColors.surface,borderRadius:BorderRadius.circular(10),
                border:Border.all(color:AppColors.border,width:0.5)),
              padding:const EdgeInsets.symmetric(horizontal:8,vertical:6),
              child:Row(
                mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                crossAxisAlignment:CrossAxisAlignment.end,
                children:List.generate(16,(i){
                  final h=(4+_beat.spectrum[i*2]*26).clamp(4.0,26.0);
                  return AnimatedContainer(
                    duration:const Duration(milliseconds:40),
                    width:8,height:h,
                    decoration:BoxDecoration(
                      borderRadius:BorderRadius.circular(2),
                      color:AppColors.primary.withOpacity(0.5+_beat.spectrum[i*2]*0.5)),
                  );
                }),
              ),
            )),
            const SizedBox(width:10),
            // BPM tap
            GestureDetector(
              onTap:_tapTempo,
              child:Container(
                width:74,height:38,
                decoration:BoxDecoration(
                  color:AppColors.surface,borderRadius:BorderRadius.circular(10),
                  border:Border.all(color:AppColors.border,width:0.5)),
                child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Text('$_bpm',style:const TextStyle(fontFamily:'Inter',
                      fontSize:16,fontWeight:FontWeight.w800,color:AppColors.textPrimary)),
                  const Text('TAP BPM',style:TextStyle(fontFamily:'Inter',
                      fontSize:7,fontWeight:FontWeight.w700,color:AppColors.textTertiary,
                      letterSpacing:1.2)),
                ]),
              ),
            ),
          ]),
        ),

        // ── Band energy meters ─────────────────────────────────────────────
        Padding(
          padding:const EdgeInsets.fromLTRB(20,8,20,16),
          child:Container(
            padding:const EdgeInsets.all(12),
            decoration:BoxDecoration(
              color:AppColors.surface,borderRadius:BorderRadius.circular(12),
              border:Border.all(color:AppColors.border,width:0.5)),
            child:Column(children:[
              ...[
                ('Sub-bass',_beat.sub,  '20–60Hz'),
                ('Bass',    _beat.bass, '60–250Hz'),
                ('Mid',     _beat.mid,  '250–4kHz'),
                ('Treble',  _beat.treble,'10–20kHz'),
              ].map((band)=>Padding(
                padding:const EdgeInsets.only(bottom:5),
                child:Row(children:[
                  SizedBox(width:52,child:Text(band.$1,style:const TextStyle(
                      fontFamily:'Inter',fontSize:9,color:AppColors.textTertiary,
                      fontWeight:FontWeight.w600))),
                  Expanded(child:ClipRRect(
                    borderRadius:BorderRadius.circular(2),
                    child:LinearProgressIndicator(
                      value:(band.$2*1.8).clamp(0.0,1.0),
                      backgroundColor:AppColors.surfaceVariant,
                      valueColor:AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.75)),
                      minHeight:4),
                  )),
                  const SizedBox(width:8),
                  SizedBox(width:36,child:Text(band.$3,style:const TextStyle(
                      fontFamily:'Inter',fontSize:8,color:AppColors.textTertiary),
                      textAlign:TextAlign.right)),
                ]),
              )),
            ]),
          ),
        ),
        const SizedBox(height:80), // mini player space
      ]),
    );
  }

  Widget _buildCanvas(Size size) {
    switch (_mode) {
      case 0: return CustomPaint(painter:_PlasmaPainter(_beat,_beat.time));
      case 1: return CustomPaint(painter:_RadialPainter(_beat,_beat.time,_bursts));
      case 2: return CustomPaint(painter:_BarsPainter(_beat,_beat.time));
      case 3: return CustomPaint(painter:_NebulaPainter(_beat,_beat.time,_bursts));
      default: return CustomPaint(painter:_PlasmaPainter(_beat,_beat.time));
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ModeInfo {
  final String icon, label, desc;
  const _ModeInfo(this.icon, this.label, this.desc);
}

class _LiveDot extends StatefulWidget {
  final BeatEngine beat;
  const _LiveDot({required this.beat});
  @override State<_LiveDot> createState()=>_LiveDotState();
}
class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState(){super.initState();_c=AnimationController(vsync:this,duration:const Duration(milliseconds:800))..repeat(reverse:true);}
  @override void dispose(){_c.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(
    animation:_c,
    builder:(_,__)=>Container(
      width:8,height:8,
      decoration:BoxDecoration(
        shape:BoxShape.circle,
        color:AppColors.success,
        boxShadow:[BoxShadow(color:AppColors.success.withOpacity(0.5+_c.value*0.4),
            blurRadius:4+_c.value*8)]),
    ),
  );
}
