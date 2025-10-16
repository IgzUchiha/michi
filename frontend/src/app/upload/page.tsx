'use client';

import { useState } from 'react';
import { useSession } from 'next-auth/react';
import { useAccount } from 'wagmi';
import { useRouter } from 'next/navigation';
import { useDropzone } from 'react-dropzone';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { uploadMeme } from '@/lib/api';
import { Upload, Image as ImageIcon, Loader2, CheckCircle2 } from 'lucide-react';
import Image from 'next/image';

export default function UploadPage() {
  const { data: session } = useSession();
  const { address, isConnected } = useAccount();
  const router = useRouter();
  
  const [caption, setCaption] = useState('');
  const [tags, setTags] = useState('');
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imageUrl, setImageUrl] = useState('');
  const [preview, setPreview] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp']
    },
    maxFiles: 1,
    onDrop: (acceptedFiles) => {
      if (acceptedFiles.length > 0) {
        const file = acceptedFiles[0];
        setImageFile(file);
        setImageUrl('');
        
        const reader = new FileReader();
        reader.onload = () => {
          setPreview(reader.result as string);
        };
        reader.readAsDataURL(file);
      }
    }
  });

  const handleImageUrlChange = (url: string) => {
    setImageUrl(url);
    setImageFile(null);
    if (url) {
      setPreview(url);
    } else {
      setPreview(null);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!session) {
      setError('Please sign in to upload memes');
      return;
    }

    if (!imageFile && !imageUrl) {
      setError('Please provide an image file or URL');
      return;
    }

    setUploading(true);
    setError(null);

    try {
      await uploadMeme({
        caption,
        tags,
        image: imageFile || imageUrl,
        evm_address: address,
      });

      setSuccess(true);
      setTimeout(() => {
        router.push('/');
      }, 2000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to upload meme');
    } finally {
      setUploading(false);
    }
  };

  if (!session) {
    return (
      <div className="container py-12">
        <Card className="max-w-2xl mx-auto">
          <CardHeader>
            <CardTitle>Authentication Required</CardTitle>
            <CardDescription>
              Please sign in to upload memes
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => router.push('/auth/signin')}>
              Sign In
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!isConnected || !address) {
    return (
      <div className="container py-12">
        <Card className="max-w-2xl mx-auto">
          <CardHeader>
            <CardTitle>Wallet Connection Required</CardTitle>
            <CardDescription>
              Please connect your wallet to upload memes and earn rewards
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-muted-foreground">
              You need to connect your MetaMask wallet to:
            </p>
            <ul className="list-disc list-inside text-sm text-muted-foreground space-y-1">
              <li>Link your memes to your wallet address</li>
              <li>Earn ETH rewards when people like your memes</li>
              <li>Claim accumulated rewards anytime</li>
            </ul>
            <p className="text-sm font-medium">
              Click the "Connect Wallet" button in the header to get started.
            </p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="container py-12">
      <Card className="max-w-2xl mx-auto">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Upload className="h-6 w-6" />
            Upload Meme
          </CardTitle>
          <CardDescription>
            Share your best memes with the community
            {isConnected && address && (
              <span className="block mt-2 text-xs font-mono">
                Connected wallet: {address.slice(0, 6)}...{address.slice(-4)}
              </span>
            )}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {success ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <CheckCircle2 className="h-16 w-16 text-green-500 mb-4" />
              <h3 className="text-xl font-semibold mb-2">Upload Successful!</h3>
              <p className="text-muted-foreground">Redirecting to gallery...</p>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Image Upload */}
              <div className="space-y-4">
                <label className="text-sm font-medium">Image</label>
                
                <div
                  {...getRootProps()}
                  className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${
                    isDragActive
                      ? 'border-primary bg-primary/5'
                      : 'border-muted-foreground/25 hover:border-primary/50'
                  }`}
                >
                  <input {...getInputProps()} />
                  {preview ? (
                    <div className="relative w-full h-64">
                      <Image
                        src={preview}
                        alt="Preview"
                        fill
                        className="object-contain rounded-lg"
                      />
                    </div>
                  ) : (
                    <div className="flex flex-col items-center gap-2">
                      <ImageIcon className="h-12 w-12 text-muted-foreground" />
                      <p className="text-sm text-muted-foreground">
                        {isDragActive
                          ? 'Drop the image here'
                          : 'Drag & drop an image, or click to select'}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        PNG, JPG, GIF, WEBP up to 10MB
                      </p>
                    </div>
                  )}
                </div>

                <div className="relative">
                  <div className="absolute inset-0 flex items-center">
                    <span className="w-full border-t" />
                  </div>
                  <div className="relative flex justify-center text-xs uppercase">
                    <span className="bg-background px-2 text-muted-foreground">
                      Or use URL
                    </span>
                  </div>
                </div>

                <Input
                  type="url"
                  placeholder="https://example.com/image.jpg"
                  value={imageUrl}
                  onChange={(e) => handleImageUrlChange(e.target.value)}
                />
              </div>

              {/* Caption */}
              <div className="space-y-2">
                <label htmlFor="caption" className="text-sm font-medium">
                  Caption
                </label>
                <Input
                  id="caption"
                  placeholder="Enter a catchy caption..."
                  value={caption}
                  onChange={(e) => setCaption(e.target.value)}
                  required
                />
              </div>

              {/* Tags */}
              <div className="space-y-2">
                <label htmlFor="tags" className="text-sm font-medium">
                  Tags
                </label>
                <Input
                  id="tags"
                  placeholder="funny, relatable, trending (comma-separated)"
                  value={tags}
                  onChange={(e) => setTags(e.target.value)}
                />
              </div>

              {error && (
                <div className="p-3 rounded-lg bg-destructive/10 text-destructive text-sm">
                  {error}
                </div>
              )}

              <Button
                type="submit"
                className="w-full"
                disabled={uploading || (!imageFile && !imageUrl)}
              >
                {uploading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Uploading...
                  </>
                ) : (
                  <>
                    <Upload className="mr-2 h-4 w-4" />
                    Upload Meme
                  </>
                )}
              </Button>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
