/**
 * Sample React Native Share Extension
 * @flow
 */

import React, { Component } from 'react'
import Modal from 'react-native-modalbox'
import ShareExtension from './react-native-share-extension'

import {
  Text,
  TextInput,
  View,
  Image,
  TouchableOpacity
} from 'react-native'

export default class Share extends Component {
  constructor(props, context) {
    super(props, context)
    this.state = {
      isOpen: true,
      data: [],
    }
  }

  async componentDidMount() {
    try {
      const data = await ShareExtension.data();
      this.setState({
        data
      })
    } catch(e) {
      console.log('errrr', e)
    }
  }

  onClose() {
    ShareExtension.close()
  }

  closing = () => {
    this.setState({
      isOpen: false
    })
  }
  renderData(data, index) {
    return (
      <View key={index}>
        <Text>type: { data.type }</Text>
        <Text>value: { data.value }</Text>
      </View>
      );
  }

  render() {
    const dataComponent = this.state.data.map(this.renderData);
    return (
      <Modal backdrop={false}
             style={{ backgroundColor: 'transparent' }} position="center" isOpen={this.state.isOpen} onClosed={this.onClose}>
          <View style={{ alignItems: 'center', justifyContent:'center', flex: 1 }}>
            <View style={{ borderColor: 'green', borderWidth: 1, backgroundColor: 'white', height: 200, width: 300 }}>
              <TouchableOpacity onPress={this.closing}>
                <Text>Close</Text>
                {dataComponent}
              </TouchableOpacity>
            </View>
          </View>
      </Modal>
    )
  }
}
