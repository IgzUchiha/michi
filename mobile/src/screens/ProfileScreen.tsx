import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  Image,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  Dimensions,
  Alert,
  Platform,
} from 'react-native';
import { useRoute, useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuthStore } from '@/stores/authStore';
import { apiService } from '@/services/api';
import { COLORS } from '@/config/constants';
import { User, Post } from '@/types';

const { width } = Dimensions.get('window');
const GRID_SIZE = (width - 2) / 3;

export const ProfileScreen: React.FC = () => {
  const route = useRoute();
  const navigation = useNavigation();
  const { user: currentUser, logout } = useAuthStore();
  
  const routeUserId = (route.params as any)?.userId;
  const isOwnProfile = !routeUserId || routeUserId === currentUser?.wallet_address;
  
  const [profile, setProfile] = useState<User | null>(isOwnProfile ? currentUser : null);
  const [posts, setPosts] = useState<Post[]>([]);
  const [isFollowing, setIsFollowing] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!isOwnProfile && routeUserId) {
      loadProfile();
    }
    loadPosts();
  }, [routeUserId]);

  const loadProfile = async () => {
    try {
      const userData = await apiService.getUserProfile(routeUserId);
      setProfile(userData);

      if (currentUser) {
        const following = await apiService.isFollowing(
          currentUser.wallet_address,
          routeUserId
        );
        setIsFollowing(following);
      }
    } catch (error) {
      console.error('Load profile error:', error);
    }
  };

  const loadPosts = async () => {
    try {
      const userId = isOwnProfile ? currentUser?.wallet_address : routeUserId;
      if (!userId) return;

      const userPosts = await apiService.getUserPosts(userId);
      setPosts(userPosts);
    } catch (error) {
      console.error('Load posts error:', error);
    }
  };

  const handleFollow = async () => {
    if (!currentUser || !profile) return;

    setIsLoading(true);
    try {
      if (isFollowing) {
        await apiService.unfollowUser(currentUser.wallet_address, profile.wallet_address);
        setIsFollowing(false);
      } else {
        await apiService.followUser(currentUser.wallet_address, profile.wallet_address);
        setIsFollowing(true);
      }
    } catch (error) {
      console.error('Follow error:', error);
      Alert.alert('Error', 'Failed to update follow status');
    } finally {
      setIsLoading(false);
    }
  };

  const handleMessage = () => {
    if (!profile) return;
    navigation.navigate('Chat' as never, {
      userId: profile.wallet_address,
      userName: profile.display_name || profile.name || profile.username || 'User',
    } as never);
  };

  const handleEditProfile = () => {
    navigation.navigate('EditProfile' as never);
  };

  const handleLogout = () => {
    Alert.alert('Logout', 'Are you sure you want to logout?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Logout', style: 'destructive', onPress: logout },
    ]);
  };

  const handlePostPress = (postId: number) => {
    navigation.navigate('PostDetail' as never, { postId } as never);
  };

  const renderHeader = () => (
    <View style={styles.header}>
      {/* Profile Picture */}
      <View style={styles.profileSection}>
        <View style={styles.profilePictureContainer}>
          {(profile?.profile_picture_url || profile?.profile_picture) ? (
            <Image
              source={{ uri: profile.profile_picture_url || profile.profile_picture }}
              style={styles.profilePicture}
            />
          ) : (
            <LinearGradient
              colors={[COLORS.gradient.start, COLORS.gradient.end]}
              style={styles.profilePicture}
            >
              <Ionicons name="person" size={50} color={COLORS.background} />
            </LinearGradient>
          )}
        </View>

        {/* Stats */}
        <View style={styles.statsContainer}>
          <View style={styles.stat}>
            <Text style={styles.statNumber}>{posts.length}</Text>
            <Text style={styles.statLabel}>Posts</Text>
          </View>
          <TouchableOpacity
            style={styles.stat}
            onPress={() =>
              navigation.navigate('Followers' as never, {
                userId: profile?.wallet_address,
              } as never)
            }
          >
            <Text style={styles.statNumber}>{profile?.followers_count || 0}</Text>
            <Text style={styles.statLabel}>Followers</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.stat}
            onPress={() =>
              navigation.navigate('Following' as never, {
                userId: profile?.wallet_address,
              } as never)
            }
          >
            <Text style={styles.statNumber}>{profile?.following_count || 0}</Text>
            <Text style={styles.statLabel}>Following</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Bio */}
      <View style={styles.bioSection}>
        <Text style={styles.name}>
          {profile?.display_name || profile?.name || profile?.username || 'Anonymous'}
        </Text>
        {profile?.bio && <Text style={styles.bio}>{profile.bio}</Text>}
        {profile?.wallet_address && (
          <Text style={styles.wallet}>
            {profile.wallet_address.slice(0, 6)}...{profile.wallet_address.slice(-4)}
          </Text>
        )}
      </View>

      {/* Action Buttons */}
      <View style={styles.actionsContainer}>
        {isOwnProfile ? (
          <>
            <TouchableOpacity style={styles.primaryButton} onPress={handleEditProfile}>
              <Text style={styles.primaryButtonText}>Edit Profile</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
              <Ionicons name="log-out-outline" size={18} color={COLORS.error} />
              <Text style={styles.logoutText}>Logout</Text>
            </TouchableOpacity>
          </>
        ) : (
          <>
            <TouchableOpacity
              style={[
                styles.primaryButton,
                isFollowing && styles.secondaryButton,
              ]}
              onPress={handleFollow}
              disabled={isLoading}
            >
              <Text
                style={[
                  styles.primaryButtonText,
                  isFollowing && styles.secondaryButtonText,
                ]}
              >
                {isFollowing ? 'Following' : 'Follow'}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.secondaryButton} onPress={handleMessage}>
              <Text style={styles.secondaryButtonText}>Message</Text>
            </TouchableOpacity>
          </>
        )}
      </View>

      {/* Grid Header */}
      <View style={styles.gridHeader}>
        <Ionicons name="grid" size={24} color={COLORS.text} />
      </View>
    </View>
  );

  const renderPost = ({ item }: { item: Post }) => (
    <TouchableOpacity
      style={styles.gridItem}
      onPress={() => handlePostPress(item.id)}
    >
      <Image source={{ uri: item.image }} style={styles.gridImage} />
      {item.media_type === 'video' && (
        <View style={styles.videoIndicator}>
          <Ionicons name="play" size={20} color={COLORS.background} />
        </View>
      )}
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={posts}
        renderItem={renderPost}
        keyExtractor={(item) => item.id.toString()}
        ListHeaderComponent={renderHeader}
        numColumns={3}
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
    paddingTop: 50,
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  profileSection: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  profilePictureContainer: {
    marginRight: 32,
  },
  profilePicture: {
    width: 88,
    height: 88,
    borderRadius: 44,
    justifyContent: 'center',
    alignItems: 'center',
  },
  statsContainer: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  stat: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 18,
    fontWeight: '700',
    color: COLORS.text,
  },
  statLabel: {
    fontSize: 14,
    color: COLORS.textSecondary,
    marginTop: 4,
  },
  bioSection: {
    marginBottom: 16,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: 4,
  },
  bio: {
    fontSize: 14,
    color: COLORS.text,
    lineHeight: 20,
    marginBottom: 4,
  },
  wallet: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  actionsContainer: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 16,
  },
  primaryButton: {
    flex: 1,
    height: 36,
    backgroundColor: COLORS.primary,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  primaryButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.background,
  },
  secondaryButton: {
    flex: 1,
    height: 36,
    backgroundColor: COLORS.surface,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  secondaryButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.text,
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 36,
    paddingHorizontal: 16,
    backgroundColor: COLORS.surface,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.error,
    gap: 6,
  },
  logoutText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.error,
  },
  gridHeader: {
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    paddingVertical: 12,
    alignItems: 'center',
  },
  gridItem: {
    width: GRID_SIZE,
    height: GRID_SIZE,
    margin: 0.5,
    position: 'relative',
  },
  gridImage: {
    width: '100%',
    height: '100%',
  },
  videoIndicator: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: 'rgba(0,0,0,0.6)',
    borderRadius: 12,
    padding: 4,
  },
});
