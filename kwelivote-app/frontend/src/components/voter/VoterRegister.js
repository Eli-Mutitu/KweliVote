import React, { useState, useEffect } from 'react';
import VoterStep1 from './VoterStep1';
import VoterStep2 from './VoterStep2';
import { voterAPI } from '../../utils/api';
import blockchainService from '../../services/BlockchainService';

const VoterRegister = () => {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState({
    // Personal information (Step 1)
    nationalid: '',
    firstname: '',
    middlename: '',
    surname: '',
    designatedPollingStation: '',
    
    // Biometric data (Step 2)
    biometricData: null,
    biometricImage: null,
  });
  
  const [showSuccess, setShowSuccess] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  
  // Search-related states
  const [searchTerm, setSearchTerm] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState([]);
  const [showSearchResults, setShowSearchResults] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [editingVoterId, setEditingVoterId] = useState(null);
  
  // Add instance counter to force component remount after submission
  const [instanceKey, setInstanceKey] = useState(0);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };
  
  const handleFileChange = (e) => {
    const { name, files } = e.target;
    if (files && files[0]) {
      setFormData({
        ...formData,
        [name]: files[0],
      });
    }
  };
  
  const nextStep = () => {
    setCurrentStep(currentStep + 1);
    window.scrollTo(0, 0);
  };
  
  const prevStep = () => {
    setCurrentStep(currentStep - 1);
    window.scrollTo(0, 0);
  };

  const handleSearch = async () => {
    if (!searchTerm.trim()) {
      setError('Please enter a search term');
      return;
    }
    
    setIsSearching(true);
    setError('');
    
    try {
      const results = await voterAPI.searchVoters(searchTerm);
      setSearchResults(results);
      setShowSearchResults(true);
    } catch (error) {
      console.error('Error searching voters:', error);
      setError(error.message || 'Failed to search voters. Please try again.');
    } finally {
      setIsSearching(false);
    }
  };
  
  const clearSearch = () => {
    setSearchTerm('');
    setSearchResults([]);
    setShowSearchResults(false);
  };
  
  const selectVoterToEdit = async (voter) => {
    try {
      // Load voter details
      const voterDetails = await voterAPI.getVoterById(voter.nationalid);
      
      // Update form data with voter details
      setFormData({
        nationalid: voterDetails.nationalid || '',
        firstname: voterDetails.firstname || '',
        middlename: voterDetails.middlename || '',
        surname: voterDetails.surname || '',
        designatedPollingStation: voterDetails.designated_polling_station || '',
        biometricData: null,
        biometricImage: null,
      });
      
      // Update state variables
      setShowSearchResults(false);
      setIsEditMode(true);
      setEditingVoterId(voter.nationalid);
      setSearchTerm('');
      
      // Reset to step 1
      setCurrentStep(1);
    } catch (error) {
      console.error('Error loading voter details:', error);
      setError(error.message || 'Failed to load voter details. Please try again.');
    }
  };
  
  // Add useEffect to auto-redirect to step 1 after successful save
  useEffect(() => {
    let redirectTimer;
    
    // Only auto-redirect when we have a success message AND it includes a blockchain transaction ID
    // or the transaction is confirmed but didn't return an ID (fallback case)
    if (showSuccess && 
        (successMessage.includes('Blockchain Transaction ID:') || 
         successMessage.includes('confirmation pending'))) {
      
      // Only proceed if we're not still waiting for blockchain confirmation
      if (!successMessage.includes('Waiting for blockchain confirmation')) {
        // Set a timer to automatically redirect to step 1 after showing success message
        redirectTimer = setTimeout(() => {
          // Reset form data for next voter
          setFormData({
            nationalid: '',
            firstname: '',
            middlename: '',
            surname: '',
            designatedPollingStation: '',
            biometricData: null,
            biometricImage: null,
          });
          
          // Navigate to step 1
          setCurrentStep(1);
          
          // Increment instance key to ensure fresh fingerprint component when they get back to step 2
          setInstanceKey(prevKey => prevKey + 1);
          
          // Clear success message
          setShowSuccess(false);
          
          // Reset edit mode if we were editing
          if (isEditMode) {
            setIsEditMode(false);
            setEditingVoterId(null);
          }
        }, 5000); // 5 seconds delay to ensure user sees the blockchain transaction ID
      }
    }
    
    // Cleanup timer if component unmounts
    return () => {
      if (redirectTimer) clearTimeout(redirectTimer);
    };
  }, [showSuccess, successMessage, isEditMode]);

  // Function to poll for blockchain transaction status
  const pollForTransactionStatus = async (voterId, initialTxId, isUpdate = false, blockchainSkipped = false) => {
    let attempts = 0;
    const maxAttempts = 15; // Maximum polling attempts
    const pollInterval = 2000; // Poll every 2 seconds
    let txId = initialTxId;
    
    // Set a temporary informational message
    if (blockchainSkipped) {
      // If blockchain storage was skipped due to insufficient funds
      setSuccessMessage(isUpdate 
        ? 'Voter record updated in database only. Blockchain registration skipped due to insufficient funds.' 
        : 'Voter registered in database only. Blockchain registration skipped due to insufficient funds.');
      setShowSuccess(true);
      setIsSubmitting(false);
      return;
    }
    
    // Normal flow when blockchain transaction is expected
    setSuccessMessage(isUpdate 
      ? 'Voter record updated. Waiting for blockchain confirmation...' 
      : 'Voter registered. Waiting for blockchain confirmation...');
    setShowSuccess(true);
    
    // Keep polling until we get a transaction ID or hit max attempts
    while (attempts < maxAttempts && (!txId || txId === 'pending')) {
      try {
        console.log(`Polling for transaction status, attempt ${attempts + 1}/${maxAttempts}`);
        
        // Wait before polling
        await new Promise(resolve => setTimeout(resolve, pollInterval));
        
        // Get the voter record with the latest status
        const voterRecord = await voterAPI.getVoterById(voterId);
        
        // Check for transaction ID - it might be in different fields
        const blockchainTxId = voterRecord.blockchain_tx_id || voterRecord.transactionId;
        
        if (blockchainTxId && blockchainTxId !== 'pending') {
          txId = blockchainTxId;
          console.log('Blockchain transaction confirmed:', txId);
          break;
        }
        
        attempts++;
      } catch (err) {
        console.error('Error polling for transaction status:', err);
        attempts++;
      }
    }
    
    // Update the success message with the transaction ID
    if (txId && txId !== 'pending') {
      setSuccessMessage(isUpdate 
        ? `Voter record updated successfully! Blockchain Transaction ID: ${txId}`
        : `Voter registered successfully! Blockchain Transaction ID: ${txId}`);
    } else {
      // If we couldn't get a transaction ID after polling
      setSuccessMessage(isUpdate 
        ? 'Voter record updated successfully! Blockchain confirmation pending.'
        : 'Voter registered successfully! Blockchain confirmation pending.');
    }
    
    // Keep showing the success message - useEffect will handle resetting the form
    setIsSubmitting(false);
  };
  
  // Function to handle saving voter DID to the blockchain
  const saveToBlockchain = async (nationalId, did, options = {}) => {
    try {
      // Check if blockchain should be skipped
      if (options.skipBlockchain) {
        console.log('Skipping blockchain storage due to configuration');
        return { 
          success: false, 
          error: 'Blockchain storage skipped', 
          skipped: true 
        };
      }

      // Check if there's a global setting to skip blockchain
      if (blockchainService.skipBlockchainOnInsufficientFunds && blockchainService.skipBlockchainOnInsufficientFunds()) {
        console.log('Skipping blockchain storage due to insufficient funds setting');
        return { 
          success: false, 
          error: 'Blockchain transactions are disabled due to insufficient funds',
          errorCode: 'BLOCKCHAIN_DISABLED',
          skipped: true
        };
      }
      if (!did) {
        console.warn('No DID provided for blockchain storage');
        return { success: false, error: 'No DID provided' };
      }

      console.log(`Saving DID to blockchain for voter with National ID: ${nationalId}`);
      console.log('DID value to store:', did);
      
      // Initialize blockchain service connection
      console.log('Initializing blockchain service...');
      const isInitialized = await blockchainService.initialize();
      console.log('Blockchain initialization result:', isInitialized);
      
      if (!isInitialized) {
        console.error('Failed to initialize blockchain connection');
        return { success: false, error: 'Blockchain connection failed' };
      }
      
      // Get private key from environment variable
      const privateKey = process.env.REACT_APP_ADMIN_PRIVATE_KEY;
      console.log('Private key available:', privateKey ? 'Yes (length: ' + privateKey.length + ')' : 'No');
      
      if (!privateKey) {
        console.error('No admin private key available');
        return { success: false, error: 'Admin private key not configured' };
      }
      
      // Import the private key
      console.log('Importing private key...');
      const importResult = await blockchainService.importPrivateKey(privateKey);
      console.log('Import private key result:', importResult);
      
      if (!importResult.success) {
        console.error('Failed to import private key:', importResult.error);
        return { success: false, error: importResult.error };
      }
      
      // Store the DID on the blockchain
      console.log('Calling blockchain service to store DID...');
      const result = await blockchainService.storeDID(nationalId, did);
      console.log('Blockchain storage result:', result);
      
      // If this is an insufficient funds error, provide a more helpful message
      if (result.errorCode === 'INSUFFICIENT_FUNDS') {
        console.error('Insufficient funds for blockchain transaction');
        console.log('Wallet address:', result.walletAddress);
        console.log('Current balance:', result.balance, 'APE');
        
        // We'll continue with the registration process but inform the user
        // that the blockchain storage failed due to insufficient funds
        return {
          success: false,
          error: 'Insufficient APE tokens for blockchain transaction. The voter will be registered in the database only.',
          isInsufficientFunds: true,
          walletAddress: result.walletAddress,
          balance: result.balance
        };
      }
      
      return result;
    } catch (error) {
      console.error('Error saving to blockchain:', error);
      return { success: false, error: error.message };
    }
  };
  
  const handleFormSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError('');
    setShowSuccess(false);
    
    try {
      // First validate all required fields
      const requiredFields = ['firstname', 'surname', 'nationalid', 'designatedPollingStation'];
      const missingFields = requiredFields.filter(field => !formData[field]);
      
      if (missingFields.length > 0) {
        // Convert camelCase field names to human-readable format for the error message
        const formattedMissingFields = missingFields.map(field => {
          if (field === 'designatedPollingStation') return 'designated polling station';
          return field;
        });
        setError(`Please fill in all required fields: ${formattedMissingFields.join(', ')}`);
        setIsSubmitting(false);
        return;
      }
      
      // If we have biometric data with a DID, save it to blockchain before API call
      let blockchainResult = null;
      
      if (formData.biometricData?.did) {
        console.log('Saving voter DID to blockchain...', formData.biometricData.did);
        console.log('Voter biometric data:', formData.biometricData);
        
        try {
          // Use the dedicated function to save DID to blockchain
          blockchainResult = await saveToBlockchain(formData.nationalid, formData.biometricData.did);
          
          if (!blockchainResult.success) {
            console.error('Blockchain storage failed:', blockchainResult.error);
            
            // Special handling for insufficient funds error
            if (blockchainResult.isInsufficientFunds) {
              console.warn('Continuing with database registration despite blockchain error');
              // Display a warning but continue with registration
              setError(`Note: ${blockchainResult.error}`);
            }
          } else {
            console.log('Successfully saved DID to blockchain:', blockchainResult);
          }
        } catch (blockchainError) {
          console.error('Error during blockchain storage:', blockchainError);
          
          // Handle insufficient funds errors specially
          if (blockchainError.message && blockchainError.message.includes('insufficient funds') ||
              (blockchainError.error && blockchainError.error.includes('insufficient funds')) || 
              blockchainError.code === 'INSUFFICIENT_FUNDS') {
            
            setError('Insufficient funds to execute blockchain transaction. Voter data was saved to the database, but not to the blockchain.');
            
            // Ask user if they want to disable blockchain
            if (window.confirm('Blockchain transaction failed due to insufficient funds. Would you like to disable blockchain transactions temporarily and continue with database-only storage?')) {
              // Set global flag to skip blockchain
              blockchainService.setSkipBlockchainOnInsufficientFunds(true);
            }
          }
          // We don't want to fail the entire registration if blockchain storage fails
          // Just log the error and continue with the regular API call
        }
      }
      
      let apiResponse;
      
      // Create or update the voter record
      if (isEditMode) {
        // If we're in edit mode and have biometric data with a DID, save it to blockchain before API call
        let blockchainResult = null;
        if (formData.biometricData?.did) {
          console.log('Updating voter DID on blockchain...');
          
          try {
            // Use the dedicated function to save DID to blockchain
            blockchainResult = await saveToBlockchain(formData.nationalid, formData.biometricData.did);
            
            if (!blockchainResult.success) {
              console.error('Blockchain storage failed:', blockchainResult.error);
              
              // Special handling for insufficient funds error
              if (blockchainResult.isInsufficientFunds) {
                console.warn('Continuing with database update despite blockchain error');
                // Display a warning but continue with update
                setError(`Note: ${blockchainResult.error}`);
              }
            } else {
              console.log('Successfully saved DID to blockchain:', blockchainResult);
            }
          } catch (blockchainError) {
            console.error('Error during blockchain storage for voter update:', blockchainError);
            // We don't want to fail the entire update if blockchain storage fails
            // Just log the error and continue with the regular API call
          }
        }
        
        // For updates, use PUT with the voter's ID
        apiResponse = await voterAPI.updateVoter(editingVoterId, {
          ...formData,
          // Transform fields to match API expectations
          designated_polling_station: formData.designatedPollingStation,
          created_by: sessionStorage.getItem('userInfo') 
            ? JSON.parse(sessionStorage.getItem('userInfo')).username || 'anonymous' 
            : 'anonymous',
          // Include biometric data if available from biometric step
          ...(formData.biometricData?.did && formData.biometricData?.biometric_template ? {
            did: formData.biometricData.did,
            biometric_template: formData.biometricData.biometric_template
          } : {}),
          // Include blockchain transaction ID if available
          ...(blockchainResult?.success ? {
            blockchain_tx_id: blockchainResult.transactionHash
          } : {})
        });
        
        // Get initial transaction ID (might be pending)
        const initialTxId = apiResponse.transactionId || apiResponse.blockchain_tx_id;
        
        // Check if blockchain registration was skipped due to insufficient funds
        const blockchainSkipped = blockchainResult && 
                                 !blockchainResult.success && 
                                 blockchainResult.isInsufficientFunds;
        
        // Start polling for transaction status
        pollForTransactionStatus(editingVoterId, initialTxId, true, blockchainSkipped);
      } else {
        // For new voters, use POST with no ID
        apiResponse = await voterAPI.createVoter({
          ...formData,
          // Transform fields to match API expectations
          designated_polling_station: formData.designatedPollingStation,
          created_by: sessionStorage.getItem('userInfo') 
            ? JSON.parse(sessionStorage.getItem('userInfo')).username || 'anonymous' 
            : 'anonymous',
          // Include biometric data if available from biometric step
          ...(formData.biometricData?.did && formData.biometricData?.biometric_template ? {
            did: formData.biometricData.did,
            biometric_template: formData.biometricData.biometric_template
          } : {})
        });
        
        // Update formData with the returned ID for potential biometric updates
        const newVoterId = apiResponse.id || apiResponse.nationalid;
        setFormData(prev => ({ ...prev, id: newVoterId }));
        
        // Get initial transaction ID (might be pending)
        const initialTxId = apiResponse.transactionId || apiResponse.blockchain_tx_id;
        
        // Check if blockchain registration was skipped due to insufficient funds
        const blockchainSkipped = blockchainResult && 
                                 !blockchainResult.success && 
                                 blockchainResult.isInsufficientFunds;
        
        // Start polling for transaction status
        pollForTransactionStatus(newVoterId, initialTxId, false, blockchainSkipped);
      }
      
      // NOTE: The auto-redirect to step 1 with cleared data will happen
      // via the useEffect added above, so we're removing the manual reset here
      
    } catch (err) {
      console.error('Error saving voter:', err);
      let errorMessage = err.message || 'An error occurred while saving the voter record';
      
      // Check for blockchain-specific errors
      if (errorMessage.includes('insufficient funds') || 
          (err.error && err.error.includes('insufficient funds')) ||
          errorMessage.includes('INSUFFICIENT_FUNDS')) {
        
        // Show more user-friendly error
        errorMessage = 'Insufficient funds to execute blockchain transaction. Voter data was saved to the database, but not to the blockchain.';
        
        // Offer option to disable blockchain temporarily
        if (confirm('Blockchain transaction failed due to insufficient funds. Would you like to disable blockchain transactions temporarily and continue with database-only storage?')) {
          // Set global flag to skip blockchain
          blockchainService.setSkipBlockchainOnInsufficientFunds(true);
          errorMessage += ' Blockchain transactions have been disabled for this session.';
        }
      }
      
      setError(errorMessage);
      setIsSubmitting(false);
    }
  };
  
  const steps = [
    { number: 1, name: 'Personal Details', status: currentStep >= 1 ? 'active' : 'inactive' },
    { number: 2, name: 'Biometric Data', status: currentStep >= 2 ? 'active' : 'inactive' },
  ];
  
  return (
    <div className="max-w-3xl mx-auto animate-slide-up">
      <div className="bg-white rounded-2xl shadow-soft-lg p-8 border border-gray-100">
        <div className="mb-8 text-center">
          <h2 className="text-2xl font-bold text-kweli-dark mb-3">
            {isEditMode ? 'Update Voter' : 'Register Voter'}
          </h2>
          <p className="text-gray-600">
            {isEditMode 
              ? 'Update the voter information in the system' 
              : 'Complete the form to register a new voter in the system'}
          </p>
        </div>
        
        {/* Search section */}
        {!isEditMode && (
          <div className="mb-8 bg-gray-50 p-5 rounded-xl border border-gray-200">
            <div className="flex items-center mb-4">
              <div className="h-7 w-7 rounded-full bg-blue-100 flex items-center justify-center mr-3">
                <svg className="h-4 w-4 text-blue-500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clipRule="evenodd" />
                </svg>
              </div>
              <h3 className="font-bold text-lg text-gray-800">Search Existing Voters</h3>
            </div>
            
            <div className="flex flex-col md:flex-row gap-3">
              <div className="flex-1">
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg className="h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clipRule="evenodd" />
                    </svg>
                  </div>
                  <input
                    type="text"
                    placeholder="Search by Name or National ID"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-kweli-primary/50 focus:border-kweli-primary/50 transition-colors duration-200"
                  />
                </div>
              </div>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={handleSearch}
                  disabled={isSearching}
                  className="px-4 py-2 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition-colors flex items-center"
                >
                  {isSearching ? (
                    <>
                      <svg className="animate-spin h-4 w-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Searching...
                    </>
                  ) : 'Search'}
                </button>
                {showSearchResults && (
                  <button
                    type="button"
                    onClick={clearSearch}
                    className="px-4 py-2 bg-gray-200 text-gray-700 font-medium rounded-lg hover:bg-gray-300 transition-colors"
                  >
                    Clear
                  </button>
                )}
              </div>
            </div>
            
            {/* Search results */}
            {showSearchResults && searchResults.length > 0 && (
              <div className="mt-4 overflow-x-auto">
                <div className="inline-block min-w-full align-middle">
                  <div className="overflow-hidden border border-gray-200 rounded-lg shadow-soft-sm">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-100">
                        <tr>
                          <th scope="col" className="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                            National ID
                          </th>
                          <th scope="col" className="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                            Name
                          </th>
                          <th scope="col" className="px-4 py-3 text-left text-xs font-medium text-gray-700 uppercase tracking-wider">
                            Polling Station
                          </th>
                          <th scope="col" className="px-4 py-3 text-center text-xs font-medium text-gray-700 uppercase tracking-wider">
                            Action
                          </th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {searchResults.map((voter) => (
                          <tr key={voter.nationalid} className="hover:bg-gray-50 transition-colors duration-150">
                            <td className="px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-900">
                              {voter.nationalid}
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-700">
                              {`${voter.firstname} ${voter.middlename || ''} ${voter.surname}`}
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-700">
                              {voter.designated_polling_station}
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm text-right">
                              <button
                                type="button"
                                onClick={() => selectVoterToEdit(voter)}
                                className="inline-flex items-center justify-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-md text-white bg-kweli-primary hover:bg-kweli-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-kweli-primary/50"
                              >
                                Edit
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}
            
            {showSearchResults && searchResults.length === 0 && (
              <div className="mt-4 bg-yellow-50 border-l-4 border-yellow-400 p-4 rounded-md">
                <div className="flex items-center">
                  <svg className="h-5 w-5 text-yellow-400 mr-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2h-1V9a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                  <p className="text-sm text-yellow-700">No voters found matching your search criteria</p>
                </div>
              </div>
            )}
          </div>
        )}
        
        {/* Form steps */}
        <div className="mb-8">
          <div className="flex justify-between items-center mb-6">
            {steps.map((step) => (
              <div key={step.number} className={`flex-1 text-center ${step.status === 'active' ? 'text-kweli-primary' : 'text-gray-400'}`}>
                <div className={`w-8 h-8 mx-auto rounded-full flex items-center justify-center border-2 ${step.status === 'active' ? 'border-kweli-primary' : 'border-gray-300'}`}>
                  {step.number}
                </div>
                <p className="mt-2 text-sm">{step.name}</p>
              </div>
            ))}
          </div>
        </div>
        
        {/* Step content */}
        {currentStep === 1 && (
          <VoterStep1
            formData={formData}
            handleInputChange={handleInputChange}
            nextStep={nextStep}
          />
        )}
        {currentStep === 2 && (
          <VoterStep2
            key={`voter-step2-${instanceKey}`}
            formData={formData}
            handleFileChange={handleFileChange}
            prevStep={prevStep}
            handleSubmit={handleFormSubmit}
            isSubmitting={isSubmitting}
            onEnrollmentComplete={(templateData) => {
              console.log('Enrollment complete with template data:', templateData);
              setFormData(prev => ({
                ...prev,
                biometricData: {
                  ...prev.biometricData,
                  biometric_template: templateData.iso_template_base64
                }
              }));
            }}
            onDIDGenerated={(didResult) => {
              console.log('DID generated:', didResult);
              setFormData(prev => ({
                ...prev,
                biometricData: {
                  ...prev.biometricData,
                  did: didResult.didKey,
                  biometric_template: prev.biometricData?.biometric_template
                }
              }));
            }}
            isEditMode={isEditMode}
          />
        )}
        
        {/* Error message */}
        {error && (
          <div className="mt-4 bg-red-50 border-l-4 border-red-400 p-4 rounded-md">
            <div className="flex items-center">
              <svg className="h-5 w-5 text-red-400 mr-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2h-1V9a1 1 0 00-1-1z" clipRule="evenodd" />
            </svg>
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        )}
        
        {/* Success message */}
        {showSuccess && (
          <div className="mt-4 bg-green-50 border-l-4 border-green-400 p-4 rounded-md">
            <div className="flex">
              {successMessage.includes('Waiting for blockchain confirmation') ? (
                <svg className="animate-spin h-5 w-5 text-green-500 mr-2 flex-shrink-0" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              ) : (
                <svg className="h-5 w-5 text-green-400 mr-2 flex-shrink-0" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              )}
              <div className="text-sm text-green-700">
                {successMessage.includes('Blockchain Transaction ID:') ? (
                  <>
                    <p className="font-medium mb-1">{isEditMode ? "Voter updated successfully!" : "Voter registered successfully!"}</p>
                    <p className="font-mono bg-green-100 p-1 rounded">Blockchain Transaction ID: <span className="font-bold">{successMessage.split('Blockchain Transaction ID:')[1].trim()}</span></p>
                    <p className="mt-1 text-xs italic">The screen will reset in a few seconds...</p>
                  </>
                ) : successMessage.includes('Waiting for blockchain confirmation') ? (
                  <>
                    <p className="font-medium mb-1">Processing Blockchain Transaction</p>
                    <p>{successMessage}</p>
                    <p className="mt-1 text-xs">This may take a few moments. Please wait...</p>
                  </>
                ) : (
                  <p>{successMessage}</p>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default VoterRegister;