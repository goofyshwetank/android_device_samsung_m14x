// libSecC2ComponentStore was built against the Android 13 C2PooledBlockPool (40 bytes). The
// Android 16 one is larger, so the blob's imports are renamed to C2PooledBlockPoox, which
// wraps the real pool and fits in the old allocation.
#include <C2BufferPriv.h>

class C2PooledBlockPoox : public C2BlockPool {
  public:
    C2PooledBlockPoox(const std::shared_ptr<C2Allocator>& allocator, const local_id_t localId);
    ~C2PooledBlockPoox() override;

    local_id_t getLocalId() const override { return mPool->getLocalId(); }
    C2Allocator::id_t getAllocatorId() const override { return mPool->getAllocatorId(); }

    c2_status_t fetchLinearBlock(uint32_t capacity, C2MemoryUsage usage,
                                 std::shared_ptr<C2LinearBlock>* block) override {
        return mPool->fetchLinearBlock(capacity, usage, block);
    }
    c2_status_t fetchGraphicBlock(uint32_t width, uint32_t height, uint32_t format,
                                  C2MemoryUsage usage,
                                  std::shared_ptr<C2GraphicBlock>* block) override {
        return mPool->fetchGraphicBlock(width, height, format, usage, block);
    }
    c2_status_t fetchLinearBlock(uint32_t capacity, C2MemoryUsage usage,
                                 std::shared_ptr<C2LinearBlock>* block, C2Fence* fence) override {
        return static_cast<C2BlockPool&>(*mPool).fetchLinearBlock(capacity, usage, block, fence);
    }
    c2_status_t fetchGraphicBlock(uint32_t width, uint32_t height, uint32_t format,
                                  C2MemoryUsage usage, std::shared_ptr<C2GraphicBlock>* block,
                                  C2Fence* fence) override {
        return static_cast<C2BlockPool&>(*mPool).fetchGraphicBlock(width, height, format, usage,
                                                                   block, fence);
    }

  private:
    const std::shared_ptr<C2PooledBlockPool> mPool;
};

static_assert(sizeof(C2PooledBlockPoox) <= 40);

C2PooledBlockPoox::C2PooledBlockPoox(const std::shared_ptr<C2Allocator>& allocator,
                                     const local_id_t localId)
    : mPool(std::make_shared<C2PooledBlockPool>(allocator, localId)) {}

C2PooledBlockPoox::~C2PooledBlockPoox() = default;
