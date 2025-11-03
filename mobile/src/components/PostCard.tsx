import React, { useState } from 'react';
import {
  View,
  Text,
  Image,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Post, User } from '@/types';
import { COLORS } from '@/config/constants';
import { formatDistanceToNow } from 'date-fns';
import { ShareModal } from './ShareModal';

const { width } = Dimensions.get('window');

interface PostCardProps {
  post: Post;
  onLike: () => void;
  onComment: () => void;
  onShare: () => void;
  onUserPress: () => void;
  currentUser?: User;
}

export const PostCard: React.FC<PostCardProps> = ({
  post,
  onLike,
  onComment,
  onShare,
  onUserPress,
  currentUser,
}) => {
  const [isLiked, setIsLiked] = useState(post.is_liked || false);
  const [likesCount, setLikesCount] = useState(post.likes);
  const [showShareModal, setShowShareModal] = useState(false);

  const handleLike = async () => {
    setIsLiked(!isLiked);
    setLikesCount(isLiked ? likesCount - 1 : likesCount + 1);
    onLike();
  };

  const handleShare = () => {
    setShowShareModal(true);
    onShare();
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <TouchableOpacity style={styles.header} onPress={onUserPress}>
        <View style={styles.profilePicture}>
          {post.user?.profile_picture ? (
            <Image
              source={{ uri: post.user.profile_picture }}
              style={styles.profileImage}
            />
          ) : (
            <View style={[styles.profileImage, styles.defaultProfile]}>
              <Ionicons name="person" size={20} color={COLORS.textSecondary} />
            </View>
          )}
        </View>
        <View style={styles.userInfo}>
          <Text style={styles.username}>
            {post.user?.name || post.evm_address?.slice(0, 8)}
          </Text>
          <Text style={styles.timestamp}>
            {formatDistanceToNow(new Date(post.created_at), { addSuffix: true })}
          </Text>
        </View>
      </TouchableOpacity>

      {/* Media */}
      <View style={styles.mediaContainer}>
        {post.media_type === 'image' && post.image && (
          <Image
            source={{ uri: post.image }}
            style={styles.media}
            resizeMode="cover"
          />
        )}
        {post.media_type === 'video' && post.video && (
          <View style={styles.media}>
            <Ionicons name="play-circle" size={64} color={COLORS.primary} />
          </View>
        )}
      </View>

      {/* Actions */}
      <View style={styles.actions}>
        <TouchableOpacity style={styles.actionButton} onPress={handleLike}>
          <Ionicons
            name={isLiked ? 'heart' : 'heart-outline'}
            size={28}
            color={isLiked ? COLORS.error : COLORS.text}
          />
          <Text style={styles.actionText}>{likesCount}</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionButton} onPress={onComment}>
          <Ionicons name="chatbubble-outline" size={26} color={COLORS.text} />
          <Text style={styles.actionText}>{post.comment_count}</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.actionButton} onPress={handleShare}>
          <Ionicons name="paper-plane-outline" size={26} color={COLORS.text} />
        </TouchableOpacity>

        <View style={{ flex: 1 }} />

        <TouchableOpacity style={styles.actionButton}>
          <Ionicons
            name={post.is_saved ? 'bookmark' : 'bookmark-outline'}
            size={26}
            color={COLORS.text}
          />
        </TouchableOpacity>
      </View>

      {/* Caption */}
      {post.caption && (
        <View style={styles.captionContainer}>
          <Text style={styles.caption}>
            <Text style={styles.username}>
              {post.user?.name || 'User'}{' '}
            </Text>
            {post.caption}
          </Text>
        </View>
      )}

      {/* Tags */}
      {post.tags && (
        <Text style={styles.tags}>
          {post.tags.split(',').map(tag => `#${tag.trim()}`).join(' ')}
        </Text>
      )}

      {/* Share Modal */}
      <ShareModal
        visible={showShareModal}
        onClose={() => setShowShareModal(false)}
        post={post}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: COLORS.background,
    marginBottom: 16,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
  },
  profilePicture: {
    marginRight: 12,
  },
  profileImage: {
    width: 40,
    height: 40,
    borderRadius: 20,
  },
  defaultProfile: {
    backgroundColor: COLORS.surface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  userInfo: {
    flex: 1,
  },
  username: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.text,
  },
  timestamp: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  mediaContainer: {
    width: width,
    height: width,
    backgroundColor: COLORS.surface,
  },
  media: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    marginRight: 16,
  },
  actionText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.text,
    marginLeft: 4,
  },
  captionContainer: {
    paddingHorizontal: 12,
    paddingBottom: 4,
  },
  caption: {
    fontSize: 14,
    color: COLORS.text,
    lineHeight: 18,
  },
  tags: {
    fontSize: 14,
    color: COLORS.primary,
    paddingHorizontal: 12,
    paddingBottom: 12,
  },
});
