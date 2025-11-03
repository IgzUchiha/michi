import React, { useEffect } from 'react';
import {
  View,
  FlatList,
  StyleSheet,
  RefreshControl,
  Text,
  TouchableOpacity,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { ConversationCard } from '@/components/ConversationCard';
import { useMessageStore } from '@/stores/messageStore';
import { useAuthStore } from '@/stores/authStore';
import { apiService } from '@/services/api';
import { COLORS, POLLING_INTERVALS } from '@/config/constants';

export const MessagesScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user } = useAuthStore();
  const { conversations, isLoading, setConversations, setLoading } = useMessageStore();

  useEffect(() => {
    loadConversations();

    // Poll for new messages
    const interval = setInterval(loadConversations, POLLING_INTERVALS.messages);
    return () => clearInterval(interval);
  }, [user]);

  const loadConversations = async () => {
    if (!user) return;

    try {
      const convs = await apiService.getConversations(user.wallet_address);
      setConversations(convs);
    } catch (error) {
      console.error('Load conversations error:', error);
    }
  };

  const handleRefresh = async () => {
    setLoading(true);
    await loadConversations();
    setLoading(false);
  };

  const handleConversationPress = (userId: string, userName?: string) => {
    navigation.navigate('Chat' as never, { userId, userName } as never);
  };

  const handleNewMessage = () => {
    navigation.navigate('NewMessage' as never);
  };

  const renderEmpty = () => (
    <View style={styles.emptyContainer}>
      <Ionicons name="chatbubbles-outline" size={64} color={COLORS.textSecondary} />
      <Text style={styles.emptyText}>No messages yet</Text>
      <Text style={styles.emptySubtext}>
        Start a conversation by tapping the + button above
      </Text>
    </View>
  );

  const renderHeader = () => (
    <View style={styles.header}>
      <Text style={styles.title}>Messages</Text>
      <TouchableOpacity onPress={handleNewMessage} style={styles.newMessageButton}>
        <LinearGradient
          colors={[COLORS.gradient.start, COLORS.gradient.end]}
          style={styles.newMessageGradient}
        >
          <Ionicons name="create-outline" size={24} color={COLORS.background} />
        </LinearGradient>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      {renderHeader()}
      <FlatList
        data={conversations}
        renderItem={({ item }) => (
          <ConversationCard
            conversation={item}
            onPress={() =>
              handleConversationPress(
                item.other_user_id,
                item.other_user?.name || item.other_user_name
              )
            }
          />
        )}
        keyExtractor={(item) => item.id}
        refreshControl={
          <RefreshControl
            refreshing={isLoading}
            onRefresh={handleRefresh}
            tintColor={COLORS.primary}
          />
        }
        ListEmptyComponent={renderEmpty}
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 50,
    paddingBottom: 16,
    backgroundColor: COLORS.background,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: COLORS.text,
  },
  newMessageButton: {
    width: 44,
    height: 44,
  },
  newMessageGradient: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 80,
    paddingHorizontal: 32,
  },
  emptyText: {
    fontSize: 20,
    fontWeight: '600',
    color: COLORS.text,
    marginTop: 16,
  },
  emptySubtext: {
    fontSize: 14,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: 8,
  },
});
