import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useWalletStore } from '@/stores/walletStore';
import { COLORS } from '@/config/constants';

export const WalletConnect: React.FC = () => {
  const { address, isConnected, balance, connect, disconnect } = useWalletStore();
  const [showModal, setShowModal] = useState(false);

  const handleConnect = async () => {
    try {
      // In a real implementation, this would use WalletConnect
      // For now, we'll create a mock connection
      const mockAddress = `0x${Math.random().toString(16).slice(2, 42)}`;
      connect(mockAddress);
      Alert.alert('Success', 'Wallet connected successfully!');
      setShowModal(false);
    } catch (error) {
      console.error('Wallet connect error:', error);
      Alert.alert('Error', 'Failed to connect wallet');
    }
  };

  const handleDisconnect = () => {
    Alert.alert('Disconnect Wallet', 'Are you sure you want to disconnect?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Disconnect',
        style: 'destructive',
        onPress: () => {
          disconnect();
          setShowModal(false);
        },
      },
    ]);
  };

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  return (
    <>
      <TouchableOpacity onPress={() => setShowModal(true)}>
        {isConnected && address ? (
          <View style={styles.connectedButton}>
            <Ionicons name="wallet" size={20} color={COLORS.primary} />
            <Text style={styles.connectedText}>{formatAddress(address)}</Text>
          </View>
        ) : (
          <LinearGradient
            colors={[COLORS.gradient.start, COLORS.gradient.end]}
            style={styles.connectButton}
          >
            <Ionicons name="wallet-outline" size={20} color={COLORS.background} />
            <Text style={styles.connectText}>Connect Wallet</Text>
          </LinearGradient>
        )}
      </TouchableOpacity>

      <Modal
        visible={showModal}
        transparent
        animationType="slide"
        onRequestClose={() => setShowModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>
                {isConnected ? 'Wallet Details' : 'Connect Wallet'}
              </Text>
              <TouchableOpacity onPress={() => setShowModal(false)}>
                <Ionicons name="close" size={28} color={COLORS.text} />
              </TouchableOpacity>
            </View>

            {isConnected && address ? (
              <View style={styles.walletInfo}>
                <View style={styles.infoRow}>
                  <Text style={styles.infoLabel}>Address</Text>
                  <Text style={styles.infoValue}>{formatAddress(address)}</Text>
                </View>
                {balance && (
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Balance</Text>
                    <Text style={styles.infoValue}>{balance} ETH</Text>
                  </View>
                )}
                <TouchableOpacity
                  style={styles.disconnectButton}
                  onPress={handleDisconnect}
                >
                  <Text style={styles.disconnectText}>Disconnect Wallet</Text>
                </TouchableOpacity>
              </View>
            ) : (
              <View style={styles.connectOptions}>
                <Text style={styles.description}>
                  Connect your wallet to send tips, earn rewards, and interact with
                  crypto features.
                </Text>

                <TouchableOpacity
                  style={styles.walletOption}
                  onPress={handleConnect}
                >
                  <Ionicons name="wallet" size={32} color={COLORS.primary} />
                  <View style={styles.optionInfo}>
                    <Text style={styles.optionTitle}>MetaMask</Text>
                    <Text style={styles.optionDescription}>
                      Connect via WalletConnect
                    </Text>
                  </View>
                  <Ionicons name="chevron-forward" size={24} color={COLORS.textSecondary} />
                </TouchableOpacity>

                <Text style={styles.note}>
                  Note: Wallet connection uses WalletConnect for secure authentication
                </Text>
              </View>
            )}
          </View>
        </View>
      </Modal>
    </>
  );
};

const styles = StyleSheet.create({
  connectButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    gap: 8,
  },
  connectText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.background,
  },
  connectedButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.primary,
    gap: 8,
  },
  connectedText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.primary,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: COLORS.background,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingBottom: 40,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: COLORS.text,
  },
  walletInfo: {
    padding: 20,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  infoLabel: {
    fontSize: 14,
    color: COLORS.textSecondary,
  },
  infoValue: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.text,
  },
  disconnectButton: {
    marginTop: 20,
    padding: 16,
    backgroundColor: COLORS.error,
    borderRadius: 12,
    alignItems: 'center',
  },
  disconnectText: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.background,
  },
  connectOptions: {
    padding: 20,
  },
  description: {
    fontSize: 14,
    color: COLORS.textSecondary,
    lineHeight: 20,
    marginBottom: 20,
  },
  walletOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 12,
  },
  optionInfo: {
    flex: 1,
    marginLeft: 12,
  },
  optionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: COLORS.text,
  },
  optionDescription: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  note: {
    fontSize: 12,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: 12,
  },
});
