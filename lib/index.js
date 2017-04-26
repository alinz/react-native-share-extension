import { NativeModules } from 'react-native'

// import ShareExtension from 'react-native-share-extension'
// const { type, value } = await NativeModules.ShareExtension.data()
// NativeModules.ShareExtension.close()
export default {
  data: (appGroupId) => NativeModules.ReactNativeShareExtension.data(appGroupId),
  dataMulti: (appGroupId) => NativeModules.ReactNativeShareExtension.dataMulti(appGroupId),
  close: (appGroupId) => NativeModules.ReactNativeShareExtension.close(appGroupId)
}
