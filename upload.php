<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Handle OPTIONS request for CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$uploadDir = '/var/www/training-system/uploads/certificates/';

// Create directory if it doesn't exist
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Handle file upload
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $file = $_FILES['file'];
    
    // Validate file size (5MB max)
    if ($file['size'] > 5 * 1024 * 1024) {
        echo json_encode(['success' => false, 'error' => 'File too large. Max 5MB']);
        exit;
    }
    
    // Validate file type
    $allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 
                     'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
    if (!in_array($file['type'], $allowedTypes)) {
        echo json_encode(['success' => false, 'error' => 'Invalid file type']);
        exit;
    }
    
    // Generate unique filename
    $personId = $_POST['personId'] ?? 'unknown';
    $competencyId = $_POST['competencyId'] ?? 'unknown';
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $timestamp = time();
    $filename = "{$personId}_{$competencyId}_{$timestamp}.{$extension}";
    
    $targetPath = $uploadDir . $filename;
    
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        echo json_encode([
            'success' => true,
            'filename' => $filename,
            'originalName' => $file['name'],
            'url' => '/uploads/certificates/' . $filename,
            'size' => $file['size']
        ]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Upload failed']);
    }
    exit;
}

// Handle file deletion
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = json_decode(file_get_contents('php://input'), true);
    $filename = $data['filename'] ?? '';
    
    if ($filename && file_exists($uploadDir . $filename)) {
        if (unlink($uploadDir . $filename)) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Delete failed']);
        }
    } else {
        echo json_encode(['success' => false, 'error' => 'File not found']);
    }
    exit;
}

// Handle file download/serve
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['file'])) {
    $filename = basename($_GET['file']);
    $filepath = $uploadDir . $filename;
    
    if (file_exists($filepath)) {
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        header('Content-Length: ' . filesize($filepath));
        readfile($filepath);
    } else {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'File not found']);
    }
    exit;
}

echo json_encode(['success' => false, 'error' => 'Invalid request']);
?>
