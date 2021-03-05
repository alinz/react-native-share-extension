// Type definitions for [react-native-share-extension]
// Project: https://github.com/padlet/react-native-share-extension
declare module 'react-native-share-extension' {
  interface RNShareData {
    value: string;
    type: "text/url" | "images/*" | "text/plain";
  }
  interface RNShareFiles {
    files: RNShareData[]
  }

  interface ShareExtension {
    close(): void;
    data(): Promise<RNShareFiles>;
    openURL(uri: string): void;
  }

  const RNShareExtension: ShareExtension;
  export default RNShareExtension;
  export type { RNShareData };
}
