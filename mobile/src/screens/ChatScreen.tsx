import React, { useEffect, useState, useRef } from 'react';
import {
  View,
  FlatList,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { MessageBubble } from '@/components/MessageBubble';
import { useMessageStore } from '@/stores/messageStore';
import { useAuthStore } from '@/stores/authStore';
import { apiService } from '@/services/api';
import { COLORS, POLLING_INTERVALS } from '@/config/constants';
import { MessageContent } from '@/types';

export const ChatScreen: React.FC = () => {
  const route = useRoute();
  const navigation = useNavigation();
  const { userId, userName } = route.params as { userId: string; userName?: string };
  const { user } = useAuthStore();
  const { currentMessages, setCurrentMessages, addMessage } = useMessageStore();
  
  const [messageText, setMessageText] = useState('');
  const [isSending, setIsSending] = useState(false);
  const flatListRef = useRef<FlatList>(null);

  useEffect(() => {
    loadMessages();
    markAsRead();

    // Poll for new messages
    const interval = setInterval(loadMessages, POLLING_INTERVALS.messages);
    return () => clearInterval(interval);
  }, [userId]);

  useEffect(() => {
    // Scroll to bottom when new messages arrive
    if (currentMessages.length > 0) {
      setTimeout(() => {
        flatListRef.current?.scrollToEnd({ animated: true });
      }, 100);
    }
  }, [currentMessages]);

  const loadMessages = async () => {
    if (!user) return;

    try {
      const messages = await apiService.getMessages(user.wallet_address, userId);
      setCurrentMessages(messages);
    } catch (error) {
      console.error('Load messages error:', error);
    }
  };

  const markAsRead = async () => {
    if (!user) return;

    try {
      await apiService.markMessagesAsRead(user.wallet_address, userId);
    } catch (error) {
      console.error('Mark as read error:', error);
    }
  };

  const handleSend = async () => {
    if (!messageText.trim() || !user || isSending) return;

    const text = messageText.trim();
    setMessageText('');
    setIsSending(true);

    try {
      const content: MessageContent = {
        type: 'text',
        text,
      };

      const message = await apiService.sendMessage({
        sender_id: user.wallet_address,
        receiver_id: userId,
        content,
      });

      addMessage(message);
    } catch (error) {
      console.error('Send message error:', error);
      Alert.alert('Error', 'Failed to send message');
      setMessageText(text);
    } finally {
      setIsSending(false);
    }
  };

  const handleSharePost = () => {
    // TODO: Implement post sharing
    Alert.alert('Coming Soon', 'Post sharing will be available soon');
  };

  const handlePostPress = (postId: number) => {
    navigation.navigate('PostDetail' as never, { postId } as never);
  };

  const renderMessage = ({ item }: { item: any }) => (
    <MessageBubble
      message={item}
      isOwnMessage={item.sender_id === user?.wallet_address}
      onPostPress={handlePostPress}
    />
  );

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={90}
    >
      <FlatList
        ref={flatListRef}
        data={currentMessages}
        renderItem={renderMessage}
        keyExtractor={(item) => item.id.toString()}
        contentContainerStyle={styles.messagesList}
        showsVerticalScrollIndicator={false}
        inverted={false}
      />

      <View style={styles.inputContainer}>
        <TouchableOpacity style={styles.iconButton} onPress={handleSharePost}>
          <Ionicons name="add-circle-outline" size={28} color={COLORS.primary} />
        </TouchableOpacity>

        <TextInput
          style={styles.input}
          placeholder="Message..."
          placeholderTextColor={COLORS.textSecondary}
          value={messageText}
          onChangeText={setMessageText}
          multiline
          maxLength={500}
        />

        <TouchableOpacity
          style={styles.sendButton}
          onPress={handleSend}
          disabled={!messageText.trim() || isSending}
        >
          <Ionicons
            name="send"
            size={24}
            color={messageText.trim() ? COLORS.primary : COLORS.textSecondary}
          />
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  messagesList: {
    paddingVertical: 16,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: COLORS.background,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
  iconButton: {
    padding: 8,
  },
  input: {
    flex: 1,
    minHeight: 40,
    maxHeight: 100,
    backgroundColor: COLORS.surface,
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 10,
    fontSize: 16,
    color: COLORS.text,
    marginHorizontal: 8,
  },
  sendButton: {
    padding: 8,
  },
});
