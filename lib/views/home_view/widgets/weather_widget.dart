import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shimmers/shimmer_weather.dart';
import '../controller/weather_controller.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final WeatherController controller = Get.find<WeatherController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(
          () => Container(
        width: 330.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E0FF).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: controller.isLoading.value
            ? const ShimmerWeather()
            : controller.errorMessage.value.isNotEmpty
            ? _buildEmptyWeatherData(colorScheme)
            : _buildWeatherData(context, controller, colorScheme),
      ),
    );
  }

  Widget _buildWeatherData(BuildContext context, WeatherController controller,
      ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.city.value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: controller.fetchWeatherData,
              child: Icon(
                Icons.refresh,
                size: 20.sp,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              'https://openweathermap.org/img/wn/${controller.icon.value}@2x.png',
              width: 50.w,
              height: 50.h,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 30.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      controller.temperature.value,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  controller.greeting.value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sunrise: ${controller.sunrise.value}',
              style: TextStyle(
                fontSize: 12.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Sunset: ${controller.sunset.value}',
              style: TextStyle(
                fontSize: 12.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyWeatherData(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_off,
          size: 40.sp,
          color: colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: 8.h),
        Text(
          'No Weather Data',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Check connection or location settings',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
