import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  FlatList,
  StyleSheet,
  RefreshControl,
  ActivityIndicator,
  Text,
  TouchableOpacity,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { PostCard } from '@/components/PostCard';
import { useFeedStore } from '@/stores/feedStore';
import { useAuthStore } from '@/stores/authStore';
import { apiService } from '@/services/api';
import { COLORS } from '@/config/constants';
import { Post } from '@/types';

export const HomeScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user } = useAuthStore();
  const {
    posts,
    isLoading,
    isRefreshing,
    hasMore,
    page,
    setPosts,
    addPosts,
    updatePost,
    setLoading,
    setRefreshing,
    incrementPage,
  } = useFeedStore();

  const [activeTab, setActiveTab] = useState<'following' | 'forYou'>('forYou');

  useEffect(() => {
    loadPosts();
  }, []);

  const loadPosts = async () => {
    if (isLoading) return;

    try {
      setLoading(true);
      let fetchedPosts: Post[];

      if (activeTab === 'following' && user) {
        fetchedPosts = await apiService.getFollowingFeed(user.wallet_address);
      } else {
        fetchedPosts = await apiService.getPosts(1, 20);
      }

      setPosts(fetchedPosts);
    } catch (error) {
      console.error('Load posts error:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadMorePosts = async () => {
    if (isLoading || !hasMore) return;

    try {
      setLoading(true);
      const nextPage = page + 1;
      const fetchedPosts = await apiService.getPosts(nextPage, 20);
      addPosts(fetchedPosts);
      incrementPage();
    } catch (error) {
      console.error('Load more posts error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadPosts();
    setRefreshing(false);
  };

  const handleLike = async (postId: number) => {
    try {
      const post = posts.find((p) => p.id === postId);
      if (!post) return;

      if (post.is_liked) {
        await apiService.unlikePost(postId);
        updatePost(postId, {
          is_liked: false,
          likes: post.likes - 1,
        });
      } else {
        await apiService.likePost(postId);
        updatePost(postId, {
          is_liked: true,
          likes: post.likes + 1,
        });
      }
    } catch (error) {
      console.error('Like error:', error);
    }
  };

  const handleComment = (postId: number) => {
    navigation.navigate('PostDetail' as never, { postId } as never);
  };

  const handleShare = (postId: number) => {
    // Share functionality already handled in PostCard
  };

  const handleUserPress = (userId: string) => {
    navigation.navigate('Profile' as never, { userId } as never);
  };

  const handleTabChange = async (tab: 'following' | 'forYou') => {
    if (tab === activeTab) return;
    
    setActiveTab(tab);
    setLoading(true);
    setPosts([]);
    
    try {
      let fetchedPosts: Post[];
      if (tab === 'following' && user) {
        fetchedPosts = await apiService.getFollowingFeed(user.wallet_address);
      } else {
        fetchedPosts = await apiService.getPosts(1, 20);
      }
      setPosts(fetchedPosts);
    } catch (error) {
      console.error('Tab change error:', error);
    } finally {
      setLoading(false);
    }
  };

  const renderHeader = () => (
    <View style={styles.header}>
      <Text style={styles.logo}>Rustaceaans</Text>
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'forYou' && styles.tabActive]}
          onPress={() => handleTabChange('forYou')}
        >
          <Text
            style={[styles.tabText, activeTab === 'forYou' && styles.tabTextActive]}
          >
            For You
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'following' && styles.tabActive]}
          onPress={() => handleTabChange('following')}
        >
          <Text
            style={[
              styles.tabText,
              activeTab === 'following' && styles.tabTextActive,
            ]}
          >
            Following
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  const renderPost = ({ item }: { item: Post }) => (
    <PostCard
      post={item}
      currentUser={user || undefined}
      onLike={() => handleLike(item.id)}
      onComment={() => handleComment(item.id)}
      onShare={() => handleShare(item.id)}
      onUserPress={() => handleUserPress(item.evm_address || item.user?.wallet_address || '')}
    />
  );

  const renderEmpty = () => (
    <View style={styles.emptyContainer}>
      <Ionicons name="images-outline" size={64} color={COLORS.textSecondary} />
      <Text style={styles.emptyText}>No posts yet</Text>
      <Text style={styles.emptySubtext}>
        {activeTab === 'following'
          ? 'Follow some users to see their posts here'
          : 'Be the first to share something!'}
      </Text>
    </View>
  );

  const renderFooter = () => {
    if (!isLoading || posts.length === 0) return null;
    return (
      <View style={styles.footer}>
        <ActivityIndicator size="small" color={COLORS.primary} />
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {renderHeader()}
      <FlatList
        data={posts}
        renderItem={renderPost}
        keyExtractor={(item) => item.id.toString()}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={handleRefresh}
            tintColor={COLORS.primary}
          />
        }
        onEndReached={loadMorePosts}
        onEndReachedThreshold={0.5}
        ListEmptyComponent={!isLoading ? renderEmpty : null}
        ListFooterComponent={renderFooter}
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
    backgroundColor: COLORS.background,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
    paddingTop: 50,
  },
  logo: {
    fontSize: 24,
    fontWeight: '700',
    color: COLORS.text,
    textAlign: 'center',
    paddingVertical: 12,
  },
  tabContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  tab: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabActive: {
    borderBottomColor: COLORS.primary,
  },
  tabText: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.textSecondary,
  },
  tabTextActive: {
    color: COLORS.primary,
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
  footer: {
    paddingVertical: 20,
    alignItems: 'center',
  },
});
