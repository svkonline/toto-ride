import { Wallet, Transaction } from '../types';

// In-memory wallet store
const wallets: Map<string, Wallet> = new Map();

export const getWallet = (driverId: string): Wallet => {
    if (!wallets.has(driverId)) {
        wallets.set(driverId, {
            driverId,
            balance: 0,
            transactions: []
        });
    }
    return wallets.get(driverId)!;
};

export const addTransaction = (driverId: string, amount: number, type: 'CREDIT' | 'DEBIT', description: string): Wallet => {
    const wallet = getWallet(driverId);
    const transaction: Transaction = {
        id: 'tx_' + Date.now(),
        amount,
        type,
        description,
        timestamp: Date.now()
    };

    if (type === 'CREDIT') {
        wallet.balance += amount;
    } else {
        wallet.balance -= amount;
    }

    wallet.transactions.push(transaction);
    return wallet;
};
