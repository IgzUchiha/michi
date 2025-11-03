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
  Platform,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import * as ImagePicker from 'expo-image-picker';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuthStore } from '@/stores/authStore';
import { apiService } from '@/services/api';
import { COLORS } from '@/config/constants';

export const EditProfileScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user, updateProfile } = useAuthStore();

  const [name, setName] = useState(user?.display_name || user?.name || '');
  const [bio, setBio] = useState(user?.bio || '');
  const [profilePicture, setProfilePicture] = useState(
    user?.profile_picture_url || user?.profile_picture || null
  );
  const [isSaving, setIsSaving] = useState(false);

  const pickImage = async () => {
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.8,
      });

      if (!result.canceled && result.assets[0]) {
        setProfilePicture(result.assets[0].uri);
      }
    } catch (error) {
      console.error('Pick image error:', error);
      Alert.alert('Error', 'Failed to pick image');
    }
  };

  const handleSave = async () => {
    if (!user) return;

    setIsSaving(true);

    try {
      const currentProfilePic = user?.profile_picture_url || user?.profile_picture;
      let profilePictureUrl = currentProfilePic;

      // Upload profile picture if changed
      if (profilePicture && profilePicture !== currentProfilePic) {
        const filename = `profile_${Date.now()}.jpg`;
        profilePictureUrl = await apiService.uploadImage(profilePicture, filename);
      }

      // Update profile via auth endpoint
      const updatedUser = await apiService.updateAuthProfile({
        display_name: name.trim() || undefined,
        bio: bio.trim() || undefined,
        profile_picture_url: profilePictureUrl || undefined,
      });

      // Update local store with normalized data
      await updateProfile({
        ...updatedUser,
        // Ensure backwards compatibility
        name: updatedUser.display_name || name.trim(),
        profile_picture: updatedUser.profile_picture_url || profilePictureUrl,
      });

      Alert.alert('Success', 'Profile updated successfully!', [
        {
          text: 'OK',
          onPress: () => navigation.goBack(),
        },
      ]);
    } catch (error) {
      console.error('Update profile error:', error);
      Alert.alert('Error', 'Failed to update profile. Please try again.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Ionicons name="close" size={28} color={COLORS.text} />
        </TouchableOpacity>
        <Text style={styles.title}>Edit Profile</Text>
        <TouchableOpacity onPress={handleSave} disabled={isSaving}>
          {isSaving ? (
            <ActivityIndicator color={COLORS.primary} />
          ) : (
            <Text style={styles.saveButton}>Save</Text>
          )}
        </TouchableOpacity>
      </View>

      {/* Profile Picture */}
      <View style={styles.profilePictureSection}>
        <TouchableOpacity onPress={pickImage} style={styles.profilePictureContainer}>
          {profilePicture ? (
            <Image source={{ uri: profilePicture }} style={styles.profilePicture} />
          ) : (
            <LinearGradient
              colors={[COLORS.gradient.start, COLORS.gradient.end]}
              style={styles.profilePicture}
            >
              <Ionicons name="person" size={50} color={COLORS.background} />
            </LinearGradient>
          )}
          <View style={styles.editIcon}>
            <Ionicons name="camera" size={20} color={COLORS.background} />
          </View>
        </TouchableOpacity>
        <TouchableOpacity onPress={pickImage}>
          <Text style={styles.changePhotoText}>Change Profile Photo</Text>
        </TouchableOpacity>
      </View>

      {/* Form */}
      <View style={styles.form}>
        <View style={styles.inputGroup}>
          <Text style={styles.label}>Name</Text>
          <TextInput
            style={styles.input}
            placeholder="Your name"
            placeholderTextColor={COLORS.textSecondary}
            value={name}
            onChangeText={setName}
            maxLength={50}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Bio</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Tell us about yourself..."
            placeholderTextColor={COLORS.textSecondary}
            value={bio}
            onChangeText={setBio}
            multiline
            maxLength={150}
            textAlignVertical="top"
          />
          <Text style={styles.charCount}>{bio.length}/150</Text>
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Wallet Address</Text>
          <View style={styles.walletContainer}>
            <Text style={styles.walletText}>{user?.wallet_address}</Text>
            <Text style={styles.walletNote}>Cannot be changed</Text>
          </View>
        </View>
      </View>
    </ScrollView>
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
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: COLORS.text,
  },
  saveButton: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.primary,
  },
  profilePictureSection: {
    alignItems: 'center',
    paddingVertical: 32,
  },
  profilePictureContainer: {
    position: 'relative',
    marginBottom: 12,
  },
  profilePicture: {
    width: 120,
    height: 120,
    borderRadius: 60,
    justifyContent: 'center',
    alignItems: 'center',
  },
  editIcon: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: COLORS.primary,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: COLORS.background,
  },
  changePhotoText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.primary,
  },
  form: {
    paddingHorizontal: 16,
  },
  inputGroup: {
    marginBottom: 24,
  },
  label: {
    fontSize: 14,
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
  textArea: {
    minHeight: 100,
  },
  charCount: {
    fontSize: 12,
    color: COLORS.textSecondary,
    textAlign: 'right',
    marginTop: 4,
  },
  walletContainer: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  walletText: {
    fontSize: 14,
    color: COLORS.text,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    marginBottom: 4,
  },
  walletNote: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontStyle: 'italic',
  },
});
