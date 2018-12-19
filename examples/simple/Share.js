/**
 * Sample React Native Share Extension
 * @flow
 */

import React, { Component } from 'react'
import ShareExtension from 'react-native-share-extension'
import {
  Text,
  View,
  Image,
  Modal,
  TouchableOpacity,
  StyleSheet
} from 'react-native'

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent:'center',
    flex: 1
  },
  content: {
    borderColor: 'green',
    borderWidth: 1,
    backgroundColor: 'white',
    margin: 10
  },
  image: {
    maxWidth: '70%',
    height: '70%',
    resizeMode: 'contain',
    borderRadius: 6,
    marginTop: 6
  }
});

export default class Share extends Component {
  constructor(props, context) {
    super(props, context)
    this.state = {
      modalVisible: true,
      type: '',
      value: ''
    }
  }

  async componentDidMount() {
    try {
      const { type, value } = await ShareExtension.data()
      this.setState({
        type,
        value
      })
    } catch(e) {
      console.log('errrr', e)
    }
  }

  onClose = () => ShareExtension.close()

  closing = () => this.setState({ modalVisible: false });

  render() {
    const {
      modalVisible,
      type,
      value
    } = this.state;

    return (
      <Modal
        animationType='slide'
        transparent={ false }
        visible={ modalVisible }
        onRequestClose={ this.onClose }
        onDismiss={ this.onClose }
      >
        <View style={ styles.container }>
          <View style={ styles.content }>
            <TouchableOpacity onPress={ this.closing }>
              <Text>Close</Text>
              <Text>type: { type }</Text>
              <Text>value: { value }</Text>
              { value ? <Image
                source={{
                  uri: value
                }}
                style={ styles.image }
              /> : null }
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    );
  }
}
