import UIKit
import Flutter
import GoogleMaps
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,  // ✅ `_` 추가
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

    // ✅ requestAuthorization 클로저 수정 (매개변수 추가)
    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
        if let error = error {
            print("푸시 알림 권한 요청 중 오류 발생: \(error.localizedDescription)")
        } else {
            print("푸시 알림 권한 요청 결과: \(granted)")
        }
    }

    // ✅ 원격 알림 등록
    application.registerForRemoteNotifications()

    // ✅ Google Maps API 키 설정
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSAPIKey") as? String {
        GMSServices.provideAPIKey(apiKey)
        print("Google Maps API Key Loaded from info.plist.")
    } else {
        print("Google Maps API Key is missing in info.plist!")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ 올바른 메서드 시그니처 적용
  override func application(
    _ application: UIApplication,  // ✅ `_` 추가
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
      print("APNS token: \(deviceToken)")  // ✅ 문자열 보간 수정
      // ✅ 백그라운드에서 푸시 알림을 탭했을 때 실행
      Messaging.messaging().apnsToken = deviceToken
      super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}