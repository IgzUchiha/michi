import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Image,
  Alert,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import * as ImagePicker from 'expo-image-picker';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuthStore } from '@/stores/authStore';
import { apiService } from '@/services/api';
import { COLORS, MEDIA_CONSTRAINTS } from '@/config/constants';

export const UploadScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user } = useAuthStore();

  const [mediaUri, setMediaUri] = useState<string | null>(null);
  const [mediaType, setMediaType] = useState<'image' | 'video'>('image');
  const [caption, setCaption] = useState('');
  const [tags, setTags] = useState('');
  const [isUploading, setIsUploading] = useState(false);

  const requestPermissions = async () => {
    const { status: cameraStatus } = await ImagePicker.requestCameraPermissionsAsync();
    const { status: libraryStatus } = await ImagePicker.requestMediaLibraryPermissionsAsync();

    if (cameraStatus !== 'granted' || libraryStatus !== 'granted') {
      Alert.alert(
        'Permissions Required',
        'Camera and photo library permissions are required to upload media.'
      );
      return false;
    }
    return true;
  };

  const pickFromGallery = async () => {
    const hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.All,
        allowsEditing: true,
        aspect: [4, 5],
        quality: MEDIA_CONSTRAINTS.imageQuality,
      });

      if (!result.canceled && result.assets[0]) {
        setMediaUri(result.assets[0].uri);
        setMediaType(result.assets[0].type === 'video' ? 'video' : 'image');
      }
    } catch (error) {
      console.error('Pick from gallery error:', error);
      Alert.alert('Error', 'Failed to pick media from gallery');
    }
  };

  const takePhoto = async () => {
    const hasPermission = await requestPermissions();
    if (!hasPermission) return;

    try {
      const result = await ImagePicker.launchCameraAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        aspect: [4, 5],
        quality: MEDIA_CONSTRAINTS.imageQuality,
      });

      if (!result.canceled && result.assets[0]) {
        setMediaUri(result.assets[0].uri);
        setMediaType('image');
      }
    } catch (error) {
      console.error('Take photo error:', error);
      Alert.alert('Error', 'Failed to take photo');
    }
  };

  const handleUpload = async () => {
    if (!mediaUri || !user) {
      Alert.alert('Error', 'Please select media to upload');
      return;
    }

    if (!caption.trim()) {
      Alert.alert('Error', 'Please add a caption');
      return;
    }

    setIsUploading(true);

    try {
      // Create form data
      const formData = new FormData();
      formData.append('caption', caption.trim());
      formData.append('tags', tags.trim());
      formData.append('evm_address', user.wallet_address);

      // Add media file
      const filename = mediaUri.split('/').pop() || 'upload.jpg';
      const match = /\.(\w+)$/.exec(filename);
      const type = match ? `${mediaType}/${match[1]}` : `${mediaType}/jpeg`;

      formData.append('image', {
        uri: mediaUri,
        name: filename,
        type,
      } as any);

      // Upload
      await apiService.createPost(formData);

      Alert.alert('Success', 'Post uploaded successfully!', [
        {
          text: 'OK',
          onPress: () => {
            setMediaUri(null);
            setCaption('');
            setTags('');
            navigation.navigate('Home' as never);
          },
        },
      ]);
    } catch (error) {
      console.error('Upload error:', error);
      Alert.alert('Error', 'Failed to upload post. Please try again.');
    } finally {
      setIsUploading(false);
    }
  };

  const handleRemoveMedia = () => {
    setMediaUri(null);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Ionicons name="close" size={28} color={COLORS.text} />
        </TouchableOpacity>
        <Text style={styles.title}>New Post</Text>
        <TouchableOpacity
          onPress={handleUpload}
          disabled={!mediaUri || !caption.trim() || isUploading}
        >
          {isUploading ? (
            <ActivityIndicator color={COLORS.primary} />
          ) : (
            <Text
              style={[
                styles.postButton,
                (!mediaUri || !caption.trim()) && styles.postButtonDisabled,
              ]}
            >
              Post
            </Text>
          )}
        </TouchableOpacity>
      </View>

      {/* Media Preview */}
      {mediaUri ? (
        <View style={styles.mediaPreview}>
          <Image source={{ uri: mediaUri }} style={styles.previewImage} />
          <TouchableOpacity style={styles.removeButton} onPress={handleRemoveMedia}>
            <Ionicons name="close-circle" size={32} color={COLORS.background} />
          </TouchableOpacity>
        </View>
      ) : (
        <View style={styles.uploadOptions}>
          <TouchableOpacity style={styles.uploadOption} onPress={pickFromGallery}>
            <LinearGradient
              colors={[COLORS.gradient.start, COLORS.gradient.end]}
              style={styles.uploadIcon}
            >
              <Ionicons name="images" size={40} color={COLORS.background} />
            </LinearGradient>
            <Text style={styles.uploadText}>Choose from Gallery</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.uploadOption} onPress={takePhoto}>
            <LinearGradient
              colors={[COLORS.gradient.start, COLORS.gradient.end]}
              style={styles.uploadIcon}
            >
              <Ionicons name="camera" size={40} color={COLORS.background} />
            </LinearGradient>
            <Text style={styles.uploadText}>Take Photo</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Caption Input */}
      <View style={styles.inputSection}>
        <Text style={styles.label}>Caption</Text>
        <TextInput
          style={styles.captionInput}
          placeholder="Write a caption..."
          placeholderTextColor={COLORS.textSecondary}
          value={caption}
          onChangeText={setCaption}
          multiline
          maxLength={500}
        />
        <Text style={styles.charCount}>{caption.length}/500</Text>
      </View>

      {/* Tags Input */}
      <View style={styles.inputSection}>
        <Text style={styles.label}>Tags (comma separated)</Text>
        <TextInput
          style={styles.input}
          placeholder="funny, meme, crypto..."
          placeholderTextColor={COLORS.textSecondary}
          value={tags}
          onChangeText={setTags}
          maxLength={100}
        />
      </View>

      {/* Tips */}
      <View style={styles.tipsContainer}>
        <Text style={styles.tipsTitle}>💡 Tips for great posts:</Text>
        <Text style={styles.tip}>• Use clear, high-quality images or videos</Text>
        <Text style={styles.tip}>• Write engaging captions</Text>
        <Text style={styles.tip}>• Add relevant tags to reach more people</Text>
        <Text style={styles.tip}>• Posts with crypto integration earn rewards!</Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  content: {
    paddingBottom: 32,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 50,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: COLORS.text,
  },
  postButton: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.primary,
  },
  postButtonDisabled: {
    opacity: 0.4,
  },
  mediaPreview: {
    width: '100%',
    aspectRatio: 4 / 5,
    backgroundColor: COLORS.surface,
    position: 'relative',
  },
  previewImage: {
    width: '100%',
    height: '100%',
  },
  removeButton: {
    position: 'absolute',
    top: 16,
    right: 16,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 16,
  },
  uploadOptions: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 60,
    paddingHorizontal: 32,
  },
  uploadOption: {
    alignItems: 'center',
  },
  uploadIcon: {
    width: 100,
    height: 100,
    borderRadius: 50,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  uploadText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.text,
  },
  inputSection: {
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: 8,
  },
  input: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: COLORS.text,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  captionInput: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: COLORS.text,
    borderWidth: 1,
    borderColor: COLORS.border,
    minHeight: 120,
    textAlignVertical: 'top',
  },
  charCount: {
    fontSize: 12,
    color: COLORS.textSecondary,
    textAlign: 'right',
    marginTop: 4,
  },
  tipsContainer: {
    margin: 16,
    padding: 16,
    backgroundColor: COLORS.surface,
    borderRadius: 12,
  },
  tipsTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: 8,
  },
  tip: {
    fontSize: 13,
    color: COLORS.textSecondary,
    marginBottom: 4,
  },
});
