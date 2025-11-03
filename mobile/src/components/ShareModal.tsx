import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  Modal,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  Image,
  TextInput,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { COLORS } from '@/config/constants';
import { apiService } from '@/services/api';
import { useAuthStore } from '@/stores/authStore';
import { User, Post } from '@/types';

interface ShareModalProps {
  visible: boolean;
  onClose: () => void;
  post: Post | null;
}

export const ShareModal: React.FC<ShareModalProps> = ({ visible, onClose, post }) => {
  const { user: currentUser } = useAuthStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [selectedUsers, setSelectedUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSending, setIsSending] = useState(false);

  useEffect(() => {
    if (visible) {
      // Reset state when modal opens
      setSearchQuery('');
      setSelectedUsers([]);
      setUsers([]);
    }
  }, [visible]);

  const handleSearch = async (query: string) => {
    setSearchQuery(query);
    
    if (query.trim().length < 2) {
      setUsers([]);
      return;
    }

    setIsLoading(true);
    try {
      const results = await apiService.searchUsers(query);
      const filtered = results.filter(u => 
        u.wallet_address !== currentUser?.wallet_address &&
        u.user_id !== currentUser?.user_id
      );
      setUsers(filtered);
    } catch (error) {
      console.error('Search error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleUserSelection = (user: User) => {
    setSelectedUsers(prev => {
      const isSelected = prev.some(u => 
        u.wallet_address === user.wallet_address || u.user_id === user.user_id
      );
      
      if (isSelected) {
        return prev.filter(u => 
          u.wallet_address !== user.wallet_address && u.user_id !== user.user_id
        );
      } else {
        return [...prev, user];
      }
    });
  };

  const handleSend = async () => {
    if (!post || selectedUsers.length === 0 || !currentUser) return;

    setIsSending(true);
    try {
      // Send message to each selected user
      await Promise.all(
        selectedUsers.map(user =>
          apiService.sendMessage({
            sender_id: currentUser.wallet_address || currentUser.user_id?.toString() || '',
            receiver_id: user.wallet_address || user.user_id?.toString() || '',
            content: {
              type: 'post' as const,
              text: `Check out this post! ${post.caption || ''}`,
              media_url: post.image || post.video,
            },
          })
        )
      );

      Alert.alert('Success', `Sent to ${selectedUsers.length} ${selectedUsers.length === 1 ? 'person' : 'people'}!`);
      onClose();
    } catch (error) {
      console.error('Send error:', error);
      Alert.alert('Error', 'Failed to send. Please try again.');
    } finally {
      setIsSending(false);
    }
  };

  const renderUser = ({ item }: { item: User }) => {
    const isSelected = selectedUsers.some(u => 
      u.wallet_address === item.wallet_address || u.user_id === item.user_id
    );

    return (
      <TouchableOpacity
        style={styles.userItem}
        onPress={() => toggleUserSelection(item)}
      >
        <View style={styles.userInfo}>
          {(item.profile_picture_url || item.profile_picture) ? (
            <Image
              source={{ uri: item.profile_picture_url || item.profile_picture }}
              style={styles.avatar}
            />
          ) : (
            <LinearGradient
              colors={[COLORS.gradient.start, COLORS.gradient.end]}
              style={styles.avatar}
            >
              <Ionicons name="person" size={20} color={COLORS.background} />
            </LinearGradient>
          )}
          <View style={styles.userDetails}>
            <Text style={styles.userName}>
              {item.display_name || item.name || item.username || 'User'}
            </Text>
            {item.username && (
              <Text style={styles.userHandle}>@{item.username}</Text>
            )}
          </View>
        </View>
        {isSelected ? (
          <LinearGradient
            colors={[COLORS.gradient.start, COLORS.gradient.end]}
            style={styles.checkbox}
          >
            <Ionicons name="checkmark" size={16} color={COLORS.background} />
          </LinearGradient>
        ) : (
          <View style={styles.checkboxEmpty} />
        )}
      </TouchableOpacity>
    );
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={onClose}
    >
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose}>
              <Ionicons name="close" size={28} color={COLORS.text} />
            </TouchableOpacity>
            <Text style={styles.title}>Share</Text>
            <TouchableOpacity
              onPress={handleSend}
              disabled={selectedUsers.length === 0 || isSending}
            >
              {isSending ? (
                <ActivityIndicator size="small" color={COLORS.primary} />
              ) : (
                <Text
                  style={[
                    styles.sendButton,
                    selectedUsers.length === 0 && styles.sendButtonDisabled,
                  ]}
                >
                  Send
                </Text>
              )}
            </TouchableOpacity>
          </View>

          {/* Selected Users */}
          {selectedUsers.length > 0 && (
            <View style={styles.selectedContainer}>
              <Text style={styles.selectedText}>
                To: {selectedUsers.map(u => u.display_name || u.name || u.username).join(', ')}
              </Text>
            </View>
          )}

          {/* Search Bar */}
          <View style={styles.searchContainer}>
            <Ionicons name="search" size={20} color={COLORS.textSecondary} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search users..."
              placeholderTextColor={COLORS.textSecondary}
              value={searchQuery}
              onChangeText={handleSearch}
              autoCapitalize="none"
              autoCorrect={false}
            />
          </View>

          {/* Post Preview */}
          {post && (
            <View style={styles.postPreview}>
              <Text style={styles.previewLabel}>Sharing:</Text>
              <View style={styles.previewContent}>
                {(post.image || post.video) && (
                  <Image
                    source={{ uri: post.image || post.video }}
                    style={styles.previewImage}
                  />
                )}
                <Text style={styles.previewCaption} numberOfLines={2}>
                  {post.caption || 'No caption'}
                </Text>
              </View>
            </View>
          )}

          {/* Users List */}
          {isLoading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={COLORS.primary} />
            </View>
          ) : users.length > 0 ? (
            <FlatList
              data={users}
              renderItem={renderUser}
              keyExtractor={(item) => item.wallet_address || item.user_id?.toString() || Math.random().toString()}
              contentContainerStyle={styles.listContent}
            />
          ) : searchQuery.trim().length >= 2 ? (
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyText}>No users found</Text>
            </View>
          ) : (
            <View style={styles.emptyContainer}>
              <Ionicons name="search" size={48} color={COLORS.textSecondary} />
              <Text style={styles.emptyText}>Search for users to share with</Text>
            </View>
          )}
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: COLORS.background,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '90%',
    paddingBottom: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 20,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: COLORS.text,
  },
  sendButton: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.primary,
  },
  sendButtonDisabled: {
    opacity: 0.5,
  },
  selectedContainer: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  selectedText: {
    fontSize: 14,
    color: COLORS.text,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    marginHorizontal: 16,
    marginTop: 16,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 12,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 16,
    color: COLORS.text,
  },
  postPreview: {
    margin: 16,
    padding: 12,
    backgroundColor: COLORS.surface,
    borderRadius: 12,
  },
  previewLabel: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginBottom: 8,
  },
  previewContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  previewImage: {
    width: 60,
    height: 60,
    borderRadius: 8,
  },
  previewCaption: {
    flex: 1,
    fontSize: 14,
    color: COLORS.text,
  },
  listContent: {
    paddingHorizontal: 16,
  },
  userItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  userInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  userDetails: {
    flex: 1,
  },
  userName: {
    fontSize: 15,
    fontWeight: '600',
    color: COLORS.text,
  },
  userHandle: {
    fontSize: 13,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkboxEmpty: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: COLORS.border,
  },
  loadingContainer: {
    padding: 32,
    alignItems: 'center',
  },
  emptyContainer: {
    padding: 32,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 14,
    color: COLORS.textSecondary,
    marginTop: 8,
    textAlign: 'center',
  },
});
