import { AppRegistry } from 'react-native';

import App from './app.android'
import Share from './share.android'

AppRegistry.registerComponent('Sample1', () => App);
AppRegistry.registerComponent('MyShareEx', () => Share);
