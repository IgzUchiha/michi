import React from 'react';
import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { Message } from '@/types';
import { COLORS } from '@/config/constants';
import { formatDistanceToNow } from 'date-fns';
import { LinearGradient } from 'expo-linear-gradient';

interface MessageBubbleProps {
  message: Message;
  isOwnMessage: boolean;
  onPostPress?: (postId: number) => void;
}

export const MessageBubble: React.FC<MessageBubbleProps> = ({
  message,
  isOwnMessage,
  onPostPress,
}) => {
  const renderContent = () => {
    switch (message.content.type) {
      case 'text':
        return (
          <Text style={[styles.text, isOwnMessage && styles.textOwn]}>
            {message.content.text}
          </Text>
        );

      case 'image':
        return (
          <Image
            source={{ uri: message.content.media_url }}
            style={styles.image}
            resizeMode="cover"
          />
        );

      case 'video':
        return (
          <View style={styles.videoPlaceholder}>
            <Text style={[styles.text, isOwnMessage && styles.textOwn]}>
              🎥 Video Message
            </Text>
          </View>
        );

      case 'post':
        return message.content.post ? (
          <TouchableOpacity
            onPress={() => onPostPress?.(message.content.post!.id)}
            style={styles.postContainer}
          >
            {message.content.post.image && (
              <Image
                source={{ uri: message.content.post.image }}
                style={styles.postImage}
                resizeMode="cover"
              />
            )}
            <Text style={[styles.text, isOwnMessage && styles.textOwn]}>
              {message.content.post.caption}
            </Text>
          </TouchableOpacity>
        ) : null;

      case 'meme':
        return (
          <View style={styles.memeContainer}>
            <Text style={[styles.text, isOwnMessage && styles.textOwn]}>
              🎭 Shared a meme
            </Text>
          </View>
        );

      default:
        return null;
    }
  };

  return (
    <View
      style={[
        styles.container,
        isOwnMessage ? styles.containerOwn : styles.containerOther,
      ]}
    >
      {isOwnMessage ? (
        <LinearGradient
          colors={[COLORS.gradient.start, COLORS.gradient.end]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.bubble}
        >
          {renderContent()}
        </LinearGradient>
      ) : (
        <View style={[styles.bubble, styles.bubbleOther]}>
          {renderContent()}
        </View>
      )}
      <Text
        style={[
          styles.timestamp,
          isOwnMessage ? styles.timestampOwn : styles.timestampOther,
        ]}
      >
        {formatDistanceToNow(new Date(message.timestamp), { addSuffix: true })}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginVertical: 4,
    paddingHorizontal: 12,
  },
  containerOwn: {
    alignItems: 'flex-end',
  },
  containerOther: {
    alignItems: 'flex-start',
  },
  bubble: {
    maxWidth: '75%',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
  },
  bubbleOther: {
    backgroundColor: COLORS.surface,
  },
  text: {
    fontSize: 16,
    color: COLORS.text,
  },
  textOwn: {
    color: COLORS.background,
  },
  image: {
    width: 200,
    height: 200,
    borderRadius: 12,
  },
  videoPlaceholder: {
    width: 200,
    height: 120,
    justifyContent: 'center',
    alignItems: 'center',
  },
  postContainer: {
    width: 250,
  },
  postImage: {
    width: '100%',
    height: 200,
    borderRadius: 12,
    marginBottom: 8,
  },
  memeContainer: {
    minWidth: 150,
  },
  timestamp: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginTop: 4,
  },
  timestampOwn: {
    textAlign: 'right',
  },
  timestampOther: {
    textAlign: 'left',
  },
});
