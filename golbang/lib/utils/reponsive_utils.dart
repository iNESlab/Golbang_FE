import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Bookmark section start
  static double getBookmarkFontSizeTitle(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 14.0;
    } else if (screenWidth < 900) {
      baseSize = 20.0;
    } else if (screenWidth < 1200) {
      baseSize = 28.0;
    } else {
      baseSize = 28.0;
    }

    // 가로모드일 경우 폰트 크기 보정
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }

  static double getBookmarkFontSizeDescription(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 16.0;
    } else if (screenWidth < 900) {
      baseSize = 24.0;
    } else if (screenWidth < 1200) {
      baseSize = 32.0;
    } else {
      baseSize = 32.0;
    }

    // 가로모드일 경우 폰트 크기 보정
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }

  static double getBookmarkCardWidth(double screenWidth, Orientation orientation) {
    double baseWidth;
    if (screenWidth < 600) {
      baseWidth = screenWidth * 0.25;
    } else if (screenWidth < 900) {
      baseWidth = screenWidth * 0.3;
    } else if (screenWidth < 1200) {
      baseWidth = screenWidth * 0.3;
    } else {
      baseWidth = screenWidth * 0.3;
    }

    return baseWidth;
    // return orientation == Orientation.landscape ? baseWidth * 0.9 : baseWidth;
  }

  static double getBookmarkPadding(double screenWidth, Orientation orientation) {
    double basePadding;
    if (screenWidth < 600) {
      basePadding = 6.0;
    } else if (screenWidth < 900) {
      basePadding = 12.0;
    } else if (screenWidth < 1200) {
      basePadding = 18.0;
    } else {
      basePadding = 18.0;
    }

    //return basePadding;
    return orientation == Orientation.landscape ? basePadding * 0.5 : basePadding;
  }
  // Bookmark section end

  // Section with scroll start
  static double getSWSTitleFS(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 18.0;
    } else if (screenWidth < 900) {
      baseSize = 24.0;
    } else if (screenWidth < 1200) {
      baseSize = 32.0;
    } else {
      baseSize = 32.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }
  // Section with scroll end

  // Home page start
  static double getAppBarHeight(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 50.0;
    } else if (screenWidth < 900) {
      baseSize = 62.5;
    } else if (screenWidth < 1200) {
      baseSize = 75.0;
    } else {
      baseSize = 75.0;
    }

    // 가로모드일 경우 폰트 크기 보정
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }
  static double getAppBarIconSize(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 24.0;
    } else if (screenWidth < 900) {
      baseSize = 30.0;
    } else if (screenWidth < 1200) {
      baseSize = 36.0;
    } else {
      baseSize = 36.0;
    }

    // 가로모드일 경우 폰트 크기 보정
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }
  // Home page end

  // Upcoming events start
  static double getUpcomingEventsFontSizeDescription(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 16.0;
    } else if (screenWidth < 900) {
      baseSize = 24.0;
    } else if (screenWidth < 1200) {
      baseSize = 32.0;
    } else {
      baseSize = 32.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }

  static double getUpcomingEventsButtonWidth(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 80.0;
    } else if (screenWidth < 900) {
      baseSize = 100.0;
    } else if (screenWidth < 1200) {
      baseSize = 100.0;
    } else {
      baseSize = 100.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }
  static double getUpcomingEventsButtonHeight(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 30.0;
    } else if (screenWidth < 900) {
      baseSize = 40.0;
    } else if (screenWidth < 1200) {
      baseSize = 50.0;
    } else {
      baseSize = 50.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }

  // Upcoming events end

  // Groups section start
  static double getGroupsAvatarRadius(double screenWidth, Orientation orientation) {
    double baseRadius;
    if (screenWidth < 600) {
      baseRadius = 40.0; // Small screens
    } else if (screenWidth < 900) {
      baseRadius = 50.0; // Medium screens
    } else if (screenWidth < 1200) {
      baseRadius = 60.0; // Large screens
    } else {
      baseRadius = 70.0; // Extra large screens
    }
    return orientation == Orientation.landscape ? baseRadius * 0.5 : baseRadius;
  }

  static double getGroupsPadding(double screenWidth, Orientation orientation) {
    double basePadding;
    if (screenWidth < 600) {
      basePadding = 8.0;
    } else if (screenWidth < 900) {
      basePadding = 12.0;
    } else if (screenWidth < 1200) {
      basePadding = 16.0;
    } else {
      basePadding = 20.0;
    }
    return orientation == Orientation.landscape ? basePadding * 0.5 : basePadding;
  }

  static double getGroupsHorizontalMargin(double screenWidth, Orientation orientation) {
    double baseMargin;
    if (screenWidth < 600) {
      baseMargin = 6.0;
    } else if (screenWidth < 900) {
      baseMargin = 10.0;
    } else if (screenWidth < 1200) {
      baseMargin = 12.0;
    } else {
      baseMargin = 14.0;
    }
    return orientation == Orientation.landscape ? baseMargin * 0.5 : baseMargin;
  }

  static double getGroupsTextHeight(double screenWidth, Orientation orientation) {
    double baseHeight;
    if (screenWidth < 600) {
      baseHeight = 14.0;
    } else if (screenWidth < 900) {
      baseHeight = 16.0;
    } else if (screenWidth < 1200) {
      baseHeight = 18.0;
    } else {
      baseHeight = 20.0;
    }
    return orientation == Orientation.landscape ? baseHeight * 0.5 : baseHeight;
  }

  static double getGroupsCardHeight(double avatarRadius, double textHeight, double padding) {
    double spacing = textHeight / 2;
    return avatarRadius * 2 + textHeight + spacing + padding;
  }
  // Groups section end

  // Event main page start

  static double getCalenderFontSize(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 14.0;
    } else if (screenWidth < 900) {
      baseSize = 20.0;
    } else if (screenWidth < 1200) {
      baseSize = 28.0;
    } else {
      baseSize = 28.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }

  static double getCalenderTitleFontSize(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 16.0;
    } else if (screenWidth < 900) {
      baseSize = 24.0;
    } else if (screenWidth < 1200) {
      baseSize = 32.0;
    } else {
      baseSize = 32.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
    // Event main page end
  }
  static double getEventMainTitleFS(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 18.0;
    } else if (screenWidth < 900) {
      baseSize = 24.0;
    } else if (screenWidth < 1200) {
      baseSize = 32.0;
    } else {
      baseSize = 32.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }

  static double getElevationButtonPadding(double screenWidth, Orientation orientation) {
    double basePadding;
    if (screenWidth < 600) {
      basePadding = 8.0;
    } else if (screenWidth < 900) {
      basePadding = 12.0;
    } else if (screenWidth < 1200) {
      basePadding = 16.0;
    } else {
      basePadding = 20.0;
    }
    return orientation == Orientation.landscape ? basePadding * 0.5 : basePadding;
  }

  static double getSmallFontSize(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 12.0;
    } else if (screenWidth < 900) {
      baseSize = 16.0;
    } else if (screenWidth < 1200) {
      baseSize = 20.0;
    } else {
      baseSize = 20.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }
  static double getMediumFontSize(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 14.0;
    } else if (screenWidth < 900) {
      baseSize = 20.0;
    } else if (screenWidth < 1200) {
      baseSize = 28.0;
    } else {
      baseSize = 28.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }

  static double getLargeFontSize(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 16.0;
    } else if (screenWidth < 900) {
      baseSize = 24.0;
    } else if (screenWidth < 1200) {
      baseSize = 32.0;
    } else {
      baseSize = 32.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
    // Event main page end
  }
  static double getXLargeFontSize(double screenWidth, Orientation orientation) {
    double baseSize;
    if (screenWidth < 600) {
      baseSize = 20.0;
    } else if (screenWidth < 900) {
      baseSize = 28.0;
    } else if (screenWidth < 1200) {
      baseSize = 36.0;
    } else {
      baseSize = 36.0;
    }
    return orientation == Orientation.landscape ? baseSize * 0.8 : baseSize;
  }
}