// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PersonalVault {
    address public owner;           // Address dompet pemilik vault
    uint256 public unlockTime;      // Batas waktu timestamp pembukaan kunci dana

    // Event untuk mencatat log setiap kali ada ETH masuk
    event Deposit(address indexed sender, uint256 amount);
    // Event untuk mencatat log penarikan dana yang berhasil
    event Withdrawal(uint256 amount, uint256 timestamp);
    // Event untuk mencatat perubahan perpanjangan waktu kunci
    event LockExtended(uint256 newUnlockTime);

    // Custom error jika mencoba menarik dana sebelum waktunya
    error FundsLocked();
    // Custom error jika pengakses bukan pemilik vault
    error NotOwner();
    // Custom error jika input perpanjangan waktu tidak valid
    error InvalidUnlockTime();
    // Custom error jika pengiriman ETH ke pemilik gagal
    error TransferFailed();

    // Modifier untuk membatasi akses fungsi hanya untuk pemilik
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // Constructor untuk inisialisasi pemilik awal dan waktu penguncian pertama
    constructor(uint256 _unlockTime) payable {
        if (_unlockTime <= block.timestamp) revert InvalidUnlockTime();
        owner = msg.sender;
        unlockTime = _unlockTime;
        
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    // Fungsi payable agar pemilik bisa menambahkan ETH ke dalam vault
    function deposit() public payable onlyOwner {
        emit Deposit(msg.sender, msg.value);
    }

    // Fungsi untuk menarik seluruh dana setelah masa penguncian selesai
    function withdraw() public onlyOwner {
        if (block.timestamp < unlockTime) revert FundsLocked();
        
        uint256 amount = address(this).balance;
        if (amount == 0) revert InvalidUnlockTime();

        emit Withdrawal(amount, block.timestamp);

        (bool success, ) = owner.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    // Fungsi untuk memperpanjang durasi penguncian dana
    function extendLock(uint256 newTime) public onlyOwner {
        if (newTime <= unlockTime) revert InvalidUnlockTime();
        unlockTime = newTime;
        emit LockExtended(newTime);
    }
}
