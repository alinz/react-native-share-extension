/** @format */

import {AppRegistry} from 'react-native';
import App from './App';
import Share from './Share'
import {name as appName, shareExtensionName} from './app.json';

AppRegistry.registerComponent(appName, () => App);
AppRegistry.registerComponent(shareExtensionName, () => Share);
