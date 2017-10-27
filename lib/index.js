import { NativeModules } from 'react-native'

// import ShareExtension from 'react-native-share-extension'
// const { type, value } = await NativeModules.ShareExtension.data()
// NativeModules.ShareExtension.close()
export default {
  data: () => NativeModules.ReactNativeShareExtension.data(),
  close: () => NativeModules.ReactNativeShareExtension.close(),
  clear: () => NativeModules.ReactNativeShareExtension.clear()
}
