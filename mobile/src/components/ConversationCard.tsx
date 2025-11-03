import React from 'react';
import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Conversation } from '@/types';
import { COLORS } from '@/config/constants';
import { formatDistanceToNow } from 'date-fns';
import { LinearGradient } from 'expo-linear-gradient';

interface ConversationCardProps {
  conversation: Conversation;
  onPress: () => void;
}

export const ConversationCard: React.FC<ConversationCardProps> = ({
  conversation,
  onPress,
}) => {
  const getLastMessagePreview = () => {
    if (!conversation.last_message) return 'No messages yet';

    const { content } = conversation.last_message;
    switch (content.type) {
      case 'text':
        return content.text || '';
      case 'image':
        return '📷 Image';
      case 'video':
        return '🎥 Video';
      case 'post':
        return '📝 Shared a post';
      case 'meme':
        return '🎭 Shared a meme';
      default:
        return 'Message';
    }
  };

  return (
    <TouchableOpacity style={styles.container} onPress={onPress}>
      <View style={styles.profilePicture}>
        {conversation.other_user?.profile_picture ? (
          <Image
            source={{ uri: conversation.other_user.profile_picture }}
            style={styles.profileImage}
          />
        ) : (
          <LinearGradient
            colors={[COLORS.gradient.start, COLORS.gradient.end]}
            style={styles.profileImage}
          >
            <Ionicons name="person" size={28} color={COLORS.background} />
          </LinearGradient>
        )}
        {conversation.unread_count > 0 && (
          <View style={styles.unreadDot} />
        )}
      </View>

      <View style={styles.content}>
        <View style={styles.header}>
          <Text style={styles.name} numberOfLines={1}>
            {conversation.other_user?.name || 
             conversation.other_user_name || 
             conversation.other_user_id.slice(0, 8)}
          </Text>
          <Text style={styles.timestamp}>
            {conversation.last_message
              ? formatDistanceToNow(new Date(conversation.last_message.timestamp), {
                  addSuffix: false,
                })
              : ''}
          </Text>
        </View>

        <View style={styles.messagePreview}>
          <Text
            style={[
              styles.lastMessage,
              conversation.unread_count > 0 && styles.lastMessageUnread,
            ]}
            numberOfLines={2}
          >
            {getLastMessagePreview()}
          </Text>
          {conversation.unread_count > 0 && (
            <View style={styles.unreadBadge}>
              <Text style={styles.unreadCount}>
                {conversation.unread_count}
              </Text>
            </View>
          )}
        </View>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    padding: 16,
    backgroundColor: COLORS.background,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  profilePicture: {
    marginRight: 12,
    position: 'relative',
  },
  profileImage: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
  },
  unreadDot: {
    position: 'absolute',
    top: 0,
    right: 0,
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: COLORS.primary,
    borderWidth: 2,
    borderColor: COLORS.background,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.text,
    flex: 1,
    marginRight: 8,
  },
  timestamp: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  messagePreview: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  lastMessage: {
    fontSize: 14,
    color: COLORS.textSecondary,
    flex: 1,
  },
  lastMessageUnread: {
    fontWeight: '600',
    color: COLORS.text,
  },
  unreadBadge: {
    backgroundColor: COLORS.primary,
    borderRadius: 10,
    minWidth: 20,
    height: 20,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 6,
    marginLeft: 8,
  },
  unreadCount: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.background,
  },
});
