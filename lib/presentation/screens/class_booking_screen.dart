import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:gms_mobile/presentation/widgets/image_slider_widget.dart';
import 'package:gms_mobile/core/providers/theme_provider.dart';
import 'package:gms_mobile/core/constants/app_colors.dart';
import 'package:gms_mobile/core/providers/auth_provider.dart';
import 'package:gms_mobile/core/providers/booking_provider.dart';
import 'package:gms_mobile/core/providers/payment_provider.dart';
import 'package:gms_mobile/presentation/widgets/gradient_button.dart';

class ClassBookingScreen extends StatefulWidget {
  const ClassBookingScreen({super.key});

  @override
  State<ClassBookingScreen> createState() => _ClassBookingScreenState();
}

class _ClassBookingScreenState extends State<ClassBookingScreen> {
  int _dateIndex = 0, _timeIndex = -1, _classIndex = 0;
  bool _loading = false;

  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _cancelledSlots = [];
  late final List<Map<String, dynamic>> _dates;

  // Cache for slot capacity results
  final Map<String, Map<String, dynamic>> _slotCapacityCache = {};

  final _classes = const [
    {"title": "BODYBUILDING", "image": "assets/images/bodybuilding.jpeg"},
    {"title": "YOGA", "image": "assets/images/yoga.jpeg"},
    {"title": "POWERLIFTING", "image": "assets/images/powerlifting.jpeg"},
  ];

  final _times = const [
    "06:30 - 09:00",
    "09:00 - 09:30",
    "10:30 - 11:00",
    "11:00 - 11:30",
    "13:30 - 14:00",
    "14:00 - 15:30",
    "15:30 - 17:00",
    "16:00 - 17:30",
    "18:00 - 19:30",
  ];

  LinearGradient get _gradient => LinearGradient(
        colors: AppColors.gradientBluePink,
      );

  int get _classId => _classIndex + 1;

  // month name based on currently selected date (for header)
  String get _month {
    final d = _dates[_dateIndex]['fullDate'] as DateTime;
    final m = d.month;
    return const [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ][m - 1];
  }

  @override
  void initState() {
    super.initState();
    _initDates();
    _fetchBookings();
    _fetchCancelledSlots();
  }

  void _initDates() {
    final now = DateTime.now();
    _dates = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return {
        "day": d.day.toString(),
        "label": ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][d.weekday % 7],
        "fullDate": d,
      };
    });
  }

  Future<void> _fetchBookings() async {
    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    if (auth.memberId == null) return;

    if (await booking.getMemberBookings(auth.memberId!)) {
      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(booking.memberBookings);
        });
      }
    }
  }

  Future<void> _fetchCancelledSlots() async {
    final booking = context.read<BookingProvider>();
    if (await booking.getCancelledSlots()) {
      if (mounted) {
        setState(() {
          _cancelledSlots = List<Map<String, dynamic>>.from(booking.cancelledSlots);
        });
      }
    }
  }

  bool _isBooked(int timeIndex) {
    final d = _dates[_dateIndex]['fullDate'] as DateTime;
    final slotDate = DateTime(d.year, d.month, d.day);

    return _bookings.any((b) {
      final bd = DateTime.parse(b['booking_date']).toLocal();
      return DateTime(bd.year, bd.month, bd.day) == slotDate &&
          b['booking_time'] == _times[timeIndex] &&
          b['class_id'] == _classId;
    });
  }

  bool _isCancelled(int timeIndex) {
    final d = _dates[_dateIndex]['fullDate'] as DateTime;
    final slotDate = DateTime(d.year, d.month, d.day);

    return _cancelledSlots.any((c) {
      final cd = DateTime.parse(c['cancel_date']).toLocal();
      return DateTime(cd.year, cd.month, cd.day) == slotDate &&
          c['cancel_timeslot'] == _times[timeIndex] &&
          c['class_id'] == _classId;
    });
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c),
    );
  }



  Future<void> _bookClass() async {
    if (_timeIndex == -1) return _snack('Select a time slot', Colors.red);

    final auth = context.read<AuthProvider>();
    final booking = context.read<BookingProvider>();
    final payment = context.read<PaymentProvider>();

    if (auth.memberId == null) return _snack('Login required', Colors.red);

    if (_isBooked(_timeIndex)) {
      return _snack('This slot is already booked', Colors.red);
    }

    if (_isCancelled(_timeIndex)) {
      return _snack('This class slot is cancelled', Colors.red);
    }

    setState(() => _loading = true);

    try {
      if (!await booking.getClassDetails(_classId)) {
        throw booking.error ?? 'Failed to get class details';
      }

      // override price with fixed values for each class type
      double price;
      switch (_classId) {
        case 1: // bodybuilding
          price = 400;
          break;
        case 2: // yoga
          price = 300;
          break;
        case 3: // powerlifting
          price = 400;
          break;
        default:
          // fallback to API value if available
          price = (booking.classDetails?['price'] as num?)?.toDouble() ?? 0;
      }

      final intent = await payment.createClassBookingPaymentIntent(
        amount: price,
        classId: _classId,
        memberId: auth.memberId!,
      );

      if (intent == null || !intent.containsKey('clientSecret') || !intent.containsKey('paymentIntentId')) {
        throw 'Payment intent creation failed';
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent['clientSecret'],
          merchantDisplayName: 'GMS Fitness',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await payment.recordBookingPayment(
        memberId: auth.memberId!,
        classId: _classId,
        paymentIntentId: intent['paymentIntentId'],
        amount: price,
      );

      final d = _dates[_dateIndex]['fullDate'] as DateTime;
      final date =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      if (!await booking.bookClass(
        memberId: auth.memberId!,
        classId: _classId,
        bookingDate: date,
        bookingTime: _times[_timeIndex],
        paymentIntentId: intent['paymentIntentId'],
      )) {
        throw booking.error ?? 'Booking failed';
      }

      // Invalidate slot capacity cache for this slot so UI updates
      final cacheKey = '$_classId-$date-${_times[_timeIndex]}';
      _slotCapacityCache.remove(cacheKey);

      _snack('Class booked successfully!', Colors.green);
      _timeIndex = -1;
      await _fetchBookings();
    } catch (e) {
      _snack(
        e is StripeException
            ? e.error.localizedMessage ?? 'Payment failed'
            : e.toString(),
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.watch<ThemeProvider>().getBackgroundColor(),

      body: Column(
        children: [
          ImageSliderWidget(
            items: _classes,
            autoSlide: false,
            height: size.height * .32,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            activeDotGradient: _gradient,
            inactiveDotColor: Colors.white54,
            onPageChanged: (i) => setState(() => _classIndex = i),
            overlayBuilder: (i) => Center(
              child: Text(_classes[i]['title']!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Text('$_month Schedule',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: context.watch<ThemeProvider>().getTextColor())),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _dates.length,
                      itemBuilder: (_, i) {
                        final selected = i == _dateIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _dateIndex = i),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 70,
                            decoration: BoxDecoration(
                              gradient: selected ? _gradient : null,
                              color: selected
                                  ? null
                                  : (isDark
                                      ? AppColors.darkSurfaceLight
                                      : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_dates[i]['day'],
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: selected
                                            ? Colors.white
                                            : context.watch<ThemeProvider>().getTextColor())),
                                // show abbreviation of the actual date, not global month
                                Text(
                                    '${(const [
                                            'Jan','Feb','Mar','Apr','May','Jun',
                                            'Jul','Aug','Sep','Oct','Nov','Dec'
                                          ][
                                              ((
                                                          _dates[i]['fullDate']
                                                              as DateTime)
                                                      .month -
                                                  1)
                                          ])} ${_dates[i]['day']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: selected
                                            ? Colors.white70
                                            : Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Available Time',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.watch<ThemeProvider>().getTextColor())),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.4,
                      ),
                      itemCount: _times.length,
                      itemBuilder: (_, i) {
                        final selected = i == _timeIndex;
                        final booked = _isBooked(i);
                        final cancelled = _isCancelled(i);

                        final dateStr = (_dates[_dateIndex]['fullDate'] as DateTime)
                            .toIso8601String()
                            .split('T')[0];
                        final cacheKey = '$_classId-$dateStr-${_times[i]}';

                        final future = _slotCapacityCache.containsKey(cacheKey)
                            ? Future.value(_slotCapacityCache[cacheKey])
                            : context.read<BookingProvider>().getSlotCapacity(
                                classId: _classId,
                                date: dateStr,
                                timeslot: _times[i],
                              ).then((data) {
                                if (data != null) _slotCapacityCache[cacheKey] = data;
                                return data;
                              });

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: future,
                          builder: (context, snapshot) {
                            final slotData = snapshot.data;
                            final full = slotData != null && (slotData['count'] as int) >= (slotData['capacity'] as int);
                            final isDisabled = cancelled || (full && !booked);

                            return GestureDetector(
                              onTap: isDisabled ? null : () => setState(() => _timeIndex = i),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: selected ? _gradient : null,
                                  color: selected
                                      ? null
                                      : cancelled
                                          ? const Color(0xFFD32F2F)
                                          : booked
                                              ? Colors.green
                                              : full
                                                  ? Colors.grey
                                                  : isDark
                                                      ? AppColors.darkSurfaceLight
                                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _times[i],
                                  style: TextStyle(
                                    color: selected || booked || cancelled || full
                                        ? Colors.white
                                        : context.watch<ThemeProvider>().getTextColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GradientButton(
                      label: 'Book Now',
                      onPressed: _bookClass,
                      isLoading: _loading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
